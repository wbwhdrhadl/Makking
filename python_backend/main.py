import os
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
import logging

app = FastAPI()

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# YOLO 얼굴 감지 모델 초기화
device = "cuda" if torch.cuda.is_available() else "cpu"
model = get_model("yolov5n", device=device, min_face=24)

# 전역 변수로 이미지 캐시 설정
cached_image = None
reference_encoding = None

# 이미지 저장 경로 설정
image_save_path = "downloaded_image.jpg"  # 이 경로는 사용자가 설정할 수 있습니다.

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
    global cached_image, reference_encoding, image_save_path

    data = await request.json()
    signed_url = data.get("signedUrl")
    image_data = data.get("image")

    logger.info("Processing image request...")

    if signed_url:
        logger.info(f"Processing image from signed URL: {signed_url}")
        try:
            response = requests.get(signed_url)
            image_data = np.frombuffer(response.content, np.uint8)
            image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            cached_image = rgb_image

            # 다운로드 받은 이미지를 로컬에 저장
            cv2.imwrite(image_save_path, image)
            logger.info(f"Image downloaded and cached successfully, saved locally at: {image_save_path}")
        except Exception as e:
            logger.error(f"Failed to download image from URL: {e}")
            raise HTTPException(status_code=400, detail=f"Failed to download image: {str(e)}")

        # 참조 이미지에서 얼굴 검출 및 인코딩
        if reference_encoding is None:
            process_face_data(rgb_image)
    elif image_data:
        logger.info("Processing base64 encoded image data")
        try:
            decoded_image = base64.b64decode(image_data)
            np_image = np.frombuffer(decoded_image, np.uint8)
            image = cv2.imdecode(np_image, cv2.IMREAD_COLOR)
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)  # 원본 데이터에도 색상 조정 적용
            process_uploaded_image(rgb_image)
        except Exception as e:
            logger.error(f"Failed to decode image data: {e}")
            raise HTTPException(status_code=400, detail=f"Failed to decode image: {str(e)}")
    else:
        logger.error("Invalid request: No image data or URL provided")
        raise HTTPException(status_code=400, detail="Either signedUrl or image data is required")

    return handle_image_processing(rgb_image)

def process_face_data(image):
    logger.info("Detecting face in reference image")
    boxes, _, _ = model(image, target_size=512)
    if len(boxes) > 0:
        box = boxes[0]
        x1, y1, x2, y2 = map(int, box)
        cropped_reference_face = image[y1:y2, x1:x2]
        reference_face_encodings = face_recognition.face_encodings(image, [(y1, x2, y2, x1)])
        if reference_face_encodings:
            global reference_encoding
            reference_encoding = reference_face_encodings[0]
            logger.info("Face features extracted successfully from reference image")
        else:
            logger.warning("No face features could be extracted from reference image")
    else:
        logger.warning("No face detected in reference image")

def process_uploaded_image(image):
    logger.info("Processing uploaded image for face detection and comparison")
    boxes, _, _ = model(image, target_size=512)
    if not boxes:
        logger.info("No face detected in uploaded image")
        return
    # Handle face detection in uploaded image

def handle_image_processing(image):
    # Image processing logic here, potentially returning a modified image or analysis results
    logger.info("Finalizing image processing and preparing response")
    _, img_encoded = cv2.imencode(".jpg", image)
    return JSONResponse(content={
        "message": "Image processed successfully",
        "image": base64.b64encode(img_encoded).decode("utf-8")
    }, status_code=200)

@app.post("/reset_cache")
async def reset_cache():
    global cached_image, reference_encoding
    cached_image = None
    reference_encoding = None
    logger.info("Cache reset successfully")
    return JSONResponse(content={"message": "Cache reset successfully"}, status_code=200)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
