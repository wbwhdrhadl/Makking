from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import torch
import os
import face_recognition
from sklearn.metrics.pairwise import cosine_similarity
from yolo5face.get_model import get_model
import requests
from io import BytesIO
import base64

app = FastAPI()

# YOLO 얼굴 감지 모델 초기화
device = "cuda" if torch.cuda.is_available() else "cpu"
model = get_model("yolov5n", device=device, min_face=24)


# 라플라시안 필터를 사용하여 이미지의 고주파 성분 추출
def extract_high_freq_features(image, size=(256, 256)):
    resized_image = cv2.resize(image, size)
    gray_image = cv2.cvtColor(resized_image, cv2.COLOR_BGR2GRAY)
    laplacian = cv2.Laplacian(gray_image, cv2.CV_64F)
    high_freq_features = laplacian.flatten()
    return high_freq_features


# 코사인 유사도를 이미지끼리 직접 비교
def cosine_similarity_images(img1, img2, size=(256, 256)):
    resized_img1 = cv2.resize(img1, size).flatten()
    resized_img2 = cv2.resize(img2, size).flatten()
    return cosine_similarity(resized_img1.reshape(1, -1), resized_img2.reshape(1, -1))[
        0
    ][0]


@app.post("/processImage")
async def process_image(request: Request):
    data = await request.json()
    image_url = data.get("image_url")
    if not image_url:
        raise HTTPException(status_code=400, detail="Image URL is required")

    response = requests.get(image_url)
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Failed to fetch image from URL")

    image_data = response.content
    image = cv2.imdecode(np.frombuffer(image_data, np.uint8), cv2.IMREAD_COLOR)
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    reference_image_path = "user_face_image_2.jpg"
    reference_image = cv2.imread(reference_image_path)
    reference_image = cv2.cvtColor(reference_image, cv2.COLOR_BGR2RGB)

    # 참조 이미지에서 얼굴 검출
    boxes, _, _ = model(reference_image, target_size=512)
    if len(boxes) > 0:
        box = boxes[0]
        x1, y1, x2, y2 = map(int, box)
        cropped_reference_face = reference_image[y1:y2, x1:x2]
        reference_face_encodings = face_recognition.face_encodings(
            reference_image, [(y1, x2, y2, x1)]
        )
        if reference_face_encodings:
            reference_encoding = reference_face_encodings[0]
        else:
            return JSONResponse(
                content={"message": "참조 이미지에서 얼굴 특징을 추출할 수 없습니다."},
                status_code=400,
            )
    else:
        return JSONResponse(
            content={"message": "참조 이미지에서 얼굴을 감지할 수 없습니다."},
            status_code=400,
        )

    # 업로드된 이미지에서 얼굴 검출 및 처리
    boxes, key_points, scores = model(rgb_image, target_size=512)
    if len(boxes) > 0:
        faces_info = []
        best_combined_score = float("-inf")
        most_similar_image_rect = None

        for box in boxes:
            x1, y1, x2, y2 = map(int, box)
            cropped_face = rgb_image[y1:y2, x1:x2]

            try:
                face_encodings = face_recognition.face_encodings(
                    rgb_image, [(y1, x2, y2, x1)]
                )
                if face_encodings:
                    face_encoding = face_encodings[0]
                    face_distance = np.linalg.norm(reference_encoding - face_encoding)
                    face_similarity = 1 - face_distance / np.linalg.norm(
                        reference_encoding
                    )
                    cosine_sim = cosine_similarity_images(
                        cropped_reference_face, cropped_face
                    )
                    face_similarity_normalized = face_similarity * 100
                    cosine_similarity_normalized = cosine_sim * 100
                    combined_similarity = np.mean(
                        [face_similarity_normalized, cosine_similarity_normalized]
                    )
                    faces_info.append((combined_similarity, (x1, y1, x2, y2)))

                    if combined_similarity > best_combined_score:
                        best_combined_score = combined_similarity
                        most_similar_image_rect = (x1, y1, x2, y2)
                else:
                    return JSONResponse(
                        content={"message": "얼굴 특징 벡터를 추출할 수 없습니다."},
                        status_code=400,
                    )
            except Exception as e:
                return JSONResponse(
                    content={"message": f"얼굴 특징 추출 중 오류 발생 - {str(e)}"},
                    status_code=500,
                )

        for score, (x1, y1, x2, y2) in faces_info:
            if (x1, y1, x2, y2) != most_similar_image_rect:
                face = image[y1:y2, x1:x2]
                center_x, center_y = (x2 - x1) // 2, (y2 - y1) // 2
                radius = max(center_x, center_y)
                mask = np.zeros((y2 - y1, x2 - x1), dtype=np.uint8)
                cv2.circle(mask, (center_x, center_y), radius, (255, 255, 255), -1)
                blurred_face = cv2.GaussianBlur(face, (99, 99), 50)
                face = np.where(mask[:, :, None] == 255, blurred_face, face)
                image[y1:y2, x1:x2] = face

        _, img_encoded = cv2.imencode(".jpg", image)
        return JSONResponse(
            content={
                "message": "성공적으로 처리되었습니다.",
                "image": base64.b64encode(img_encoded).decode("utf-8"),
            },
            status_code=200,
        )

    else:
        return JSONResponse(
            content={"message": "얼굴이 탐지되지 않았습니다."}, status_code=400
        )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
