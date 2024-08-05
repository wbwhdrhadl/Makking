from fastapi import FastAPI, UploadFile, File
import subprocess
import torch
import whisper
import contextlib
import wave
from fastapi.middleware.cors import CORSMiddleware
from pyannote.audio.pipelines.speaker_verification import PretrainedSpeakerEmbedding
from pyannote.audio import Audio
from pyannote.core import Segment
from sklearn.cluster import AgglomerativeClustering
import numpy as np
import datetime

app = FastAPI()

# CORS 설정 추가
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 출처 허용
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용
    allow_headers=["*"],  # 모든 HTTP 헤더 허용
)

# Initialize models
model = whisper.load_model("medium", device="cpu")
embedding_model = PretrainedSpeakerEmbedding("speechbrain/spkrec-ecapa-voxceleb", device=torch.device("cpu"))
audio = Audio()

def segment_embedding(segment, path, duration):
    start = segment["start"]
    end = min(duration, segment["end"])
    clip = Segment(start, end)
    waveform, sample_rate = audio.crop(path, clip)
    return embedding_model(waveform[None])

def time(secs):
    return str(datetime.timedelta(seconds=round(secs)))

@app.post("/transcribe/")
async def transcribe(file: UploadFile = File(...), num_speakers: int = 2):
    # Save uploaded file
    file_location = f"temp_{file.filename}"
    with open(file_location, "wb+") as f:
        f.write(file.file.read())

    # Check if the file is in MP4 format and convert to WAV
    if file_location[-3:] == 'mp4':
        subprocess.call(['ffmpeg', '-i', file_location, 'temp_audio.wav', '-y'])
        file_location = 'temp_audio.wav'

    subprocess.call(['ffmpeg', '-i', file_location, '-ac', '1', 'audio_mono.wav', '-y'])
    path = 'audio_mono.wav'

    # Load Whisper model and transcribe
    result = model.transcribe(path)
    segments = result["segments"]

    # Get duration and process embeddings
    with contextlib.closing(wave.open(path, 'r')) as f:
        frames = f.getnframes()
        rate = f.getframerate()
        duration = frames / float(rate)

    embeddings = np.zeros((len(segments), 192))
    for i, segment in enumerate(segments):
        embeddings[i] = segment_embedding(segment, path, duration)

    # Clustering
    clustering = AgglomerativeClustering(num_speakers).fit(embeddings)
    labels = clustering.labels_

    # Assign speaker labels to segments
    for i, segment in enumerate(segments):
        segment['speaker'] = labels[i] + 1

    transcript = []
    for i, segment in enumerate(segments):
        if i == 0 or segments[i - 1]["speaker"] != segment["speaker"]:
            speaker_info = f"SPEAKER {segment['speaker']} {time(segment['start'])}"
        else:
            speaker_info = None
        transcript.append({
            "start": segment["start"],
            "end": segment["end"],
            "speaker": speaker_info,
            "text": segment["text"][1:]
        })
    print(transcript)
    return {"transcript": transcript}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5003)
