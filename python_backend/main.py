from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import cv2
import numpy as np
import torch
from concurrent.futures import ThreadPoolExecutor
import base64
from yolo5face.get_model import get_model
import face_recognition
import asyncio
import logging

app = FastAPI()

# GPU 사용 여부 확인 및 모델 초기화
device = "cuda" if torch.cuda.is_available() else "cpu"
model = get_model("yolov5n", device=device, min_face=24)

# 멀티스레딩을 위한 실행자 생성
executor = ThreadPoolExecutor(max_workers=7)

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ImageData(BaseModel):
    image: str  # Base64 인코딩된 이미지 데이터

def decode_image(data):
    img_data = base64.b64decode(data)
    nparr = np.frombuffer(img_data, np.uint8)
    return cv2.imdecode(nparr, cv2.IMREAD_COLOR)

def encode_image(image):
    _, buffer = cv2.imencode('.jpg', image)
    return base64.b64encode(buffer).decode('utf-8')

def handle_image(image):
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    boxes, _, _ = model(rgb_image, target_size=512)
    logger.info(f"Detected {len(boxes)} faces")

    if not boxes:
        return image

    for box in boxes:
        x1, y1, x2, y2 = map(int, box)
        face_region = image[y1:y2, x1:x2]
        blurred_face = cv2.GaussianBlur(face_region, (99, 99), 30)
        image[y1:y2, x1:x2] = blurred_face
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)

    return image

@app.post("/process_image")
async def process_image(data: ImageData):
    try:
        loop = asyncio.get_event_loop()
        img = await loop.run_in_executor(executor, decode_image, data.image)
        processed_image = await loop.run_in_executor(executor, handle_image, img)
        jpg_as_text = await loop.run_in_executor(executor, encode_image, processed_image)
        return {"processed_image": jpg_as_text}
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")  # Detailed error log
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5003)
