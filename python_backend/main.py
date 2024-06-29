from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import cv2
import numpy as np
import torch
from yolo5face.get_model import get_model
import face_recognition
from sklearn.metrics.pairwise import cosine_similarity

app = FastAPI()

# YOLO 얼굴 감지 모델 초기화
model = get_model("yolov5n", device="cuda" if torch.cuda.is_available() else "cpu", min_face=24)

class ImageData(BaseModel):
    image: str  # Base64 인코딩된 이미지 데이터

@app.post("/process_image")
async def process_image(data: ImageData):
    try:
        img_data = base64.b64decode(data.image)
        nparr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # 이미지 처리 함수 호출
        processed_image = handle_image(img)

        _, buffer = cv2.imencode('.jpg', processed_image)
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        return {"processed_image": jpg_as_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def handle_image(image):
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    boxes, _, _ = model(rgb_image, target_size=512)

    if not boxes:
        return image  # 얼굴을 찾지 못한 경우 원본 이미지 반환

    for box in boxes:
        x1, y1, x2, y2 = map(int, box)
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 3)

    return image

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5003)
