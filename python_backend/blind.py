from fastapi import FastAPI, UploadFile, File
from google.cloud import speech_v1
from pydub import AudioSegment
import numpy as np
import io
import os
from moviepy.editor import VideoFileClip

app = FastAPI()

# Google Cloud Speech API 클라이언트 생성
client = speech_v1.SpeechClient()

# Speech to Text (STT) 함수
def sample_recognize(audio_content):
    language_code = "ko-KR"
    sample_rate_hertz = 44100
    encoding = speech_v1.RecognitionConfig.AudioEncoding.ENCODING_UNSPECIFIED

    config = {
        "language_code": language_code,
        "sample_rate_hertz": sample_rate_hertz,
        "encoding": encoding,
        "enable_word_time_offsets": True,
        "use_enhanced": True,
    }

    audio = {"content": audio_content}

    response = client.recognize(config=config, audio=audio)

    timeline, swear_timeline, words = [], [], []
    swear_words = ['씨발', '미친', '개새끼']

    for result in response.results:
        alternative = result.alternatives[0]
        for word in alternative.words:
            start_time = word.start_time.total_seconds() * 1000
            end_time = word.end_time.total_seconds() * 1000

            timeline.append([int(start_time), int(end_time)])
            words.append(word.word)

            if any(swear in word.word for swear in swear_words):
                swear_timeline.append([int(start_time), int(end_time)])

    return timeline, swear_timeline, words

# Beep 음 생성 함수
def create_beep(duration):
    sps = 44100
    freq_hz = 1000.0
    vol = 0.5

    esm = np.arange(duration / 1000 * sps)
    wf = np.sin(2 * np.pi * esm * freq_hz / sps)
    wf_quiet = wf * vol
    wf_int = np.int16(wf_quiet * 32767)

    beep = AudioSegment(
        wf_int.tobytes(),
        frame_rate=sps,
        sample_width=wf_int.dtype.itemsize,
        channels=1
    )
    return beep

# 영상에서 오디오 추출 함수 (모노로 변환)
def extract_audio_from_video(video_path, output_audio_path="temp_audio.wav"):
    video = VideoFileClip(video_path)
    audio = video.audio
    audio.write_audiofile(output_audio_path, codec='pcm_s16le')

    # 오디오 파일을 모노로 변환
    sound = AudioSegment.from_file(output_audio_path)
    sound = sound.set_channels(1)  # 모노로 변환
    
    # 변환한 오디오 다시 저장
    sound.export(output_audio_path, format="wav")
    return output_audio_path

@app.post("/process-video/")
async def process_video(file: UploadFile = File(...)):
    # 파일 저장
    video_file_path = f"temp_{file.filename}"
    with open(video_file_path, "wb") as f:
        f.write(await file.read())

    # 영상에서 오디오 추출 (모노로 변환)
    audio_file_path = extract_audio_from_video(video_file_path)

    # 추출된 오디오 파일을 Google Speech API로 분석
    with io.open(audio_file_path, "rb") as f:
        audio_content = f.read()

    # STT 및 욕설 탐지
    timeline, swear_timeline, words = sample_recognize(audio_content)

    # 원본 오디오 로드
    sound = AudioSegment.from_file(audio_file_path)

    # 욕설에 Beep 소리 삽입
    mixed_final = sound
    for i in range(len(swear_timeline)):
        duration = swear_timeline[i][1] - swear_timeline[i][0]
        if duration > 0:
            beep = create_beep(duration=duration)
            mixed_final = mixed_final.overlay(beep, position=swear_timeline[i][0], gain_during_overlay=-20)

    # 처리된 오디오 파일 저장
    output_file = f"processed_audio_{file.filename.replace('.mp4', '.mp3')}"
    mixed_final.export(output_file, format="mp3")

    # 처리된 파일 반환
    return {"message": "Audio processed successfully", "output_file": output_file}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
