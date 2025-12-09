import os
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import uuid4

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app import DigitRecognizer, RecognitionStorage
from app.recognizer import RecognitionError

app = FastAPI(title="MultiDigit Recognition Backend")

# Konfigurasi CORS supaya device mobile bisa mengakses server lokal
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

recognizer = DigitRecognizer(model_path=os.getenv("MODEL_PATH"), eager=False)
storage = RecognitionStorage(Path(UPLOAD_DIR))


@app.on_event("startup")
async def startup_event() -> None:
    try:
        recognizer.ensure_ready()
        print("Model loaded successfully")
    except FileNotFoundError as exc:
        print(f"[WARN] {exc}")
    except Exception as exc:  # pragma: no cover - diagnostic only
        print(f"[ERROR] Gagal memuat model: {exc}")


@app.get("/")
def read_root():
    return {"message": "Multidigit backend aktif"}


@app.get("/health/model")
def model_health():
    return {
        "model_path": str(recognizer.model_path),
        "ready": recognizer.is_ready,
        "last_loaded_at": recognizer.last_loaded_at,
    }


@app.post("/recognitions")
async def create_recognition(
    image: UploadFile = File(...),
    device_id: str = Form("unknown-device"),
    capture_source: str = Form("unknown"),
    timestamp: Optional[str] = Form(None),
    crop_box: Optional[str] = Form(None),
):
    if not image:
        raise HTTPException(status_code=400, detail="Image file is required")

    contents = await image.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Image file is empty")

    safe_name = image.filename or "capture.jpg"
    unique_filename = f"{uuid4().hex}_{safe_name}"
    disk_path = os.path.join(UPLOAD_DIR, unique_filename)

    with open(disk_path, "wb") as buffer:
        buffer.write(contents)

    try:
        recognition = recognizer.predict(contents)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except RecognitionError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:  # pragma: no cover - unexpected failure
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    metadata = {
        "device_id": device_id,
        "capture_source": capture_source,
        "timestamp": timestamp or datetime.utcnow().isoformat(),
        "crop_box": crop_box,
    }

    response_payload = {
        **recognition.to_dict(),
        "image_url": f"/uploads/{unique_filename}",
        "metadata": metadata,
    }

    storage.append_record({
        "file_path": disk_path,
        "prediction": response_payload["prediction"],
        "accuracy": response_payload["accuracy"],
        "processing_time_ms": response_payload["processing_time_ms"],
        "metadata": metadata,
        "digits": response_payload["digits"],
    })

    print(f"Recognition request processed: {response_payload}")
    return response_payload