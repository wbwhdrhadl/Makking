from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import torch
import face_recognition
from sklearn.metrics.pairwise import cosine_similarity
from yolo5face.get_model import get_model
import base64
import requests
from ultralytics import YOLO

app = FastAPI()

# YOLO 얼굴 감지 모델 초기화
device = "cuda" if torch.cuda.is_available() else "cpu"
model_face = get_model("yolov5n", device=device, min_face=24)
# YOLOv8 유해물질 감지 모델 불러오기
model_dangerous = YOLO('best.pt')

# 전역 변수로 이미지 캐시 및 모자이크 설정
cached_image = None
reference_encoding = None
is_mosaic_enabled_global = None  # 전역 변수로 모자이크 여부 저장 (None으로 초기화)

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
    return cosine_similarity(resized_img1.reshape(1, -1), resized_img2.reshape(1, -1))[0][0]

@app.post("/process_image")
async def process_image(request: Request):
    global cached_image, reference_encoding, is_mosaic_enabled_global

    data = await request.json()
    signed_url = data.get("signedUrl")
    image_data = data.get("image")

    # isMosaicEnabled 값을 한 번만 설정하고 이후 변경하지 않도록 유지
    if is_mosaic_enabled_global is None:
        is_mosaic_enabled_global = data.get("isMosaicEnabled", False)
    print("모자이크 여부 :", is_mosaic_enabled_global)

    if signed_url:
        # 서명된 URL을 처리하는 로직
        try:
            response = requests.get(signed_url)
            image_data = np.frombuffer(response.content, np.uint8)
            image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            cached_image = rgb_image
            print("이미지 다운로드 및 캐시 성공")
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to download image: {str(e)}")

        # 참조 이미지 설정
        reference_image = cached_image
        # 참조 이미지에서 얼굴 검출 및 인코딩
        if reference_encoding is None:
            boxes, _, _ = model_face(reference_image, target_size=512)
            if len(boxes) > 0:
                box = boxes[0]
                x1, y1, x2, y2 = map(int, box)
                cropped_reference_face = reference_image[y1:y2, x1:x2]
                reference_face_encodings = face_recognition.face_encodings(
                    reference_image, [(y1, x2, y2, x1)]
                )
                if reference_face_encodings:
                    reference_encoding = reference_face_encodings[0]
                    print("참조 이미지에서 얼굴 특징 추출 성공")
                else:
                    return JSONResponse(
                        content={"message": "참조 이미지에서 얼굴 특징을 추출할 수 없습니다."},
                        status_code=200,  # 얼굴 특징을 추출하지 못해도 200 OK를 반환
                    )
            else:
                return JSONResponse(
                    content={"message": "참조 이미지에서 얼굴을 감지할 수 없습니다."},
                    status_code=200,  # 얼굴을 감지하지 못해도 200 OK를 반환
                )

    elif image_data:
        # Base64로 인코딩된 이미지를 처리하는 로직
        try:
            decoded_image = base64.b64decode(image_data)
            np_image = np.frombuffer(decoded_image, np.uint8)
            image = cv2.imdecode(np_image, cv2.IMREAD_COLOR)
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)  # 원본 데이터에도 색상 조정 적용
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to decode image: {str(e)}")

    else:
        raise HTTPException(status_code=400, detail="Either signedUrl or image data is required")

    # 업로드된 이미지에서 얼굴 검출 및 처리
    boxes, key_points, scores = model_face(rgb_image, target_size=512)
    if len(boxes) > 0:
        faces_info = []
        best_combined_score = float("-inf")
        most_similar_image_rect = None

        for box in boxes:
            x1, y1, x2, y2 = map(int, box)
            cropped_face = rgb_image[y1:y2, x1:x2]

            try:
                face_encodings = face_recognition.face_encodings(rgb_image, [(y1, x2, y2, x1)])
                if face_encodings:
                    face_encoding = face_encodings[0]
                    face_distance = np.linalg.norm(reference_encoding - face_encoding)
                    face_similarity = 1 - face_distance / np.linalg.norm(reference_encoding)
                    cosine_sim = cosine_similarity_images(cached_image, cropped_face)
                    face_similarity_normalized = face_similarity * 100
                    cosine_similarity_normalized = cosine_sim * 100
                    combined_similarity = np.mean([face_similarity_normalized, cosine_similarity_normalized])
                    faces_info.append((combined_similarity, (x1, y1, x2, y2)))

                    if combined_similarity > best_combined_score:
                        best_combined_score = combined_similarity
                        most_similar_image_rect = (x1, y1, x2, y2)

            except Exception as e:
                return JSONResponse(
                    content={"message": f"얼굴 특징 추출 중 오류 발생 - {str(e)}"},
                    status_code=500,
                )

        # 얼굴 블러 처리
        for score, (x1, y1, x2, y2) in faces_info:
            if (x1, y1, x2, y2) != most_similar_image_rect:
                face = rgb_image[y1:y2, x1:x2]
                center_x, center_y = (x2 - x1) // 2, (y2 - y1) // 2
                radius = max(center_x, center_y)
                mask = np.zeros((y2 - y1, x2 - x1), dtype=np.uint8)
                cv2.circle(mask, (center_x, center_y), radius, (255, 255, 255), -1)
                blurred_face = cv2.GaussianBlur(face, (99, 99), 50)
                face = np.where(mask[:, :, None] == 255, blurred_face, face)
                rgb_image[y1:y2, x1:x2] = face

        # 유해물질 감지 및 처리
        if is_mosaic_enabled_global:
            print("유해물질 모자이크 처리를 시작합니다.")
            results = model_dangerous(rgb_image)
            for result in results:
                if len(result.boxes) > 0:
                    for box in result.boxes:
                        x1, y1, x2, y2 = map(int, box.xyxy[0])

                        # 유해물질 영역 크롭
                        dangerous_area = rgb_image[y1:y2, x1:x2]

                        # 중앙과 반지름 계산
                        center_x, center_y = (x2 - x1) // 2, (y2 - y1) // 2
                        radius = max(center_x, center_y)

                        # 원형 마스크 생성
                        mask = np.zeros((y2 - y1, x2 - x1), dtype=np.uint8)
                        cv2.circle(mask, (center_x, center_y), radius, (255, 255, 255), -1)

                        # 유해물질 영역을 블러 처리
                        blurred_area = cv2.GaussianBlur(dangerous_area, (99, 99), 50)
                        dangerous_area = np.where(mask[:, :, None] == 255, blurred_area, dangerous_area)

                        # 원본 이미지에 블러 처리된 유해물질 적용
                        rgb_image[y1:y2, x1:x2] = dangerous_area

        _, img_encoded = cv2.imencode(".jpg", rgb_image)
        return JSONResponse(
            content={
                "message": "성공적으로 처리되었습니다.",
                "image": base64.b64encode(img_encoded).decode("utf-8"),
            },
            status_code=200,
        )

    else:
        _, img_encoded = cv2.imencode(".jpg", rgb_image)
        return JSONResponse(
            content={
                "message": "얼굴이 탐지되지 않았습니다.",
                "image": base64.b64encode(img_encoded).decode("utf-8"),
            },
            status_code=200,
        )

@app.post("/reset_cache")
async def reset_cache():
    global cached_image, reference_encoding, is_mosaic_enabled_global
    cached_image = None
    reference_encoding = None
    is_mosaic_enabled_global = None  # 모자이크 여부 초기화
    print("캐시가 초기화되었습니다.")
    return JSONResponse(content={"message": "캐시가 초기화되었습니다."}, status_code=200)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
