from fastapi import FastAPI, File, UploadFile
from pydub import AudioSegment
from google.cloud import speech_v1
import numpy as np
import io
import os
import subprocess

app = FastAPI()

# Initialize Google Cloud Speech-to-Text client
client = speech_v1.SpeechClient()

# Define swear words list
swear_words = ['씨발', '미친', '개새끼', '존나', '년', '놈','시발']

# Function to process audio and replace swear words with beeps
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
    transcript_list = []

    for result in response.results:
        alternative = result.alternatives[0]
        for word in alternative.words:
            start_time = word.start_time.total_seconds() * 1000
            end_time = word.end_time.total_seconds() * 1000
            timeline.append([int(start_time), int(end_time)])

            if any(swear in word.word for swear in swear_words):
                swear_timeline.append([int(start_time), int(end_time)])
                transcript_list.append("**")
            else:
                transcript_list.append(word.word)

    transcript = ' '.join(transcript_list)
    return timeline, swear_timeline, transcript

# Function to create beep sound
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

@app.post("/process-audio/")
async def process_audio(file: UploadFile = File(...)):
    # Save uploaded MP4 file
    mp4_file_location = f"temp_{file.filename}"
    with open(mp4_file_location, "wb+") as f:
        f.write(file.file.read())

    # Convert MP4 to WAV using ffmpeg
    wav_file_location = "temp_audio.wav"
    subprocess.call(['ffmpeg', '-i', mp4_file_location, '-ac', '1', wav_file_location, '-y'])

    # Load the converted WAV file using pydub
    audio = AudioSegment.from_file(wav_file_location, format="wav")

    # Read the WAV file content for STT processing
    with open(wav_file_location, "rb") as f:
        audio_content = f.read()

    # Run speech-to-text with swear detection
    timeline, swear_timeline, transcript = sample_recognize(audio_content)

    # Process and overlay beep on detected swear words
    mixed_final = audio
    for i in range(len(swear_timeline)):
        duration = swear_timeline[i][1] - swear_timeline[i][0]
        if duration > 0:
            beep = create_beep(duration=duration)
            mixed_final = mixed_final.overlay(beep, position=swear_timeline[i][0], gain_during_overlay=-20)

    # Save the processed audio to a temporary file
    output_path = "processed_audio.mp3"
    mixed_final.export(output_path, format="mp3")

    # Cleanup temporary files
    os.remove(mp4_file_location)
    os.remove(wav_file_location)

    # Return processed audio and transcript as response
    return {
        "transcript": transcript,
        "file_path": output_path,
        "message": "Audio processed successfully."
    }

# To run the FastAPI server, use the following command in your terminal:
# uvicorn main:app --reload
