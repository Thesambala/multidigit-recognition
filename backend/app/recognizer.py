from __future__ import annotations

import math
import os
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

import cv2
import joblib
import numpy as np
from skimage.feature import hog


@dataclass
class DigitComponent:
    label: str
    confidence: float
    bbox: Tuple[int, int, int, int]

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class RecognitionResult:
    prediction: str
    accuracy: float
    processing_time_ms: int
    digits: List[DigitComponent]

    def to_dict(self) -> dict:
        return {
            "prediction": self.prediction,
            "accuracy": self.accuracy,
            "processing_time_ms": self.processing_time_ms,
            "digits": [digit.to_dict() for digit in self.digits],
        }


class RecognitionError(Exception):
    """Raised when the recognition pipeline cannot infer a prediction."""


class DigitRecognizer:
    def __init__(self, model_path: Optional[str] = None, eager: bool = True):
        default_path = Path(__file__).parent.parent / "models" / "svm_model.joblib"
        self.model_path = Path(model_path or os.getenv("MODEL_PATH", default_path))
        self._model = None
        self._scaler = None
        self._loaded_at: Optional[float] = None
        if eager:
            self.ensure_ready()

    @property
    def is_ready(self) -> bool:
        return self._model is not None and self._scaler is not None

    @property
    def last_loaded_at(self) -> Optional[str]:
        if self._loaded_at is None:
            return None
        return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(self._loaded_at))

    def ensure_ready(self) -> None:
        if self.is_ready:
            return
        if not self.model_path.exists():
            raise FileNotFoundError(
                f"Model artifact tidak ditemukan di {self.model_path}. "
                "Set variabel lingkungan MODEL_PATH ke file .joblib yang benar.",
            )
        artifact = joblib.load(self.model_path)
        self._model = artifact.get("model")
        self._scaler = artifact.get("scaler")
        if self._model is None or self._scaler is None:
            raise RuntimeError(
                "File model tidak valid. Harus berisi key 'model' dan 'scaler'.",
            )
        self._loaded_at = time.time()

    def predict(self, image_bytes: bytes, expected_digits: Optional[int] = None) -> RecognitionResult:
        self.ensure_ready()
        np_buffer = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(np_buffer, cv2.IMREAD_COLOR)
        if image is None:
            raise RecognitionError("Berkas gambar tidak dapat dibaca.")

        start = time.perf_counter()
        gray, std_dev = _robust_preprocessing(image)
        segments = _segment_digits(gray, std_dev, expected_digits)
        if not segments:
            raise RecognitionError("Digit tidak terdeteksi pada gambar.")

        digits: List[DigitComponent] = []
        confidences: List[float] = []
        predicted_chars: List[str] = []

        for entry in segments:
            crop = entry["crop"]
            bbox = entry["bbox"]
            features = _extract_hog(crop)
            scaled = self._scaler.transform(features.reshape(1, -1))
            label = str(self._model.predict(scaled)[0])
            confidence = _confidence_from_model(self._model, scaled)
            digits.append(
                DigitComponent(
                    label=label,
                    confidence=confidence,
                    bbox=(int(bbox[0]), int(bbox[1]), int(bbox[2]), int(bbox[3])),
                ),
            )
            predicted_chars.append(label)
            confidences.append(confidence)

        prediction = "".join(predicted_chars)
        accuracy = float(np.mean(confidences)) if confidences else 0.0
        processing_time_ms = int((time.perf_counter() - start) * 1000)

        return RecognitionResult(
            prediction=prediction,
            accuracy=round(accuracy, 2),
            processing_time_ms=processing_time_ms,
            digits=digits,
        )


def _robust_preprocessing(image: np.ndarray) -> Tuple[np.ndarray, float]:
    if image.ndim == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    blurred = cv2.GaussianBlur(gray, (3, 3), 0)
    std_dev = float(np.std(blurred))

    if std_dev < 40:
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(blurred)
        cleaned = cv2.GaussianBlur(enhanced, (3, 3), 0)
    else:
        cleaned = blurred

    return cleaned, std_dev


def _extract_hog(
    img: np.ndarray,
    pixels_per_cell: Tuple[int, int] = (4, 4),
    cells_per_block: Tuple[int, int] = (2, 2),
    orientations: int = 9,
    transform_sqrt: bool = True,
    block_norm: str = "L2-Hys",
) -> np.ndarray:
    if img.shape != (28, 28):
        img = cv2.resize(img, (28, 28), interpolation=cv2.INTER_AREA)
    return hog(
        img,
        orientations=orientations,
        pixels_per_cell=pixels_per_cell,
        cells_per_block=cells_per_block,
        transform_sqrt=transform_sqrt,
        block_norm=block_norm,
        feature_vector=True,
    )


def _resize_and_center(img: np.ndarray, size: int = 28) -> np.ndarray:
    if img is None or img.size == 0:
        return np.zeros((size, size), dtype=np.uint8)
    h, w = img.shape[:2]
    if h < 1 or w < 1:
        return np.zeros((size, size), dtype=np.uint8)
    scale = size / max(h, w)
    new_h = max(1, int(h * scale))
    new_w = max(1, int(w * scale))
    resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((size, size), dtype=np.uint8)
    ch = (size - new_h) // 2
    cw = (size - new_w) // 2
    canvas[ch:ch + new_h, cw:cw + new_w] = resized
    return canvas


def _segment_digits(
    img_gray: np.ndarray,
    std_dev: float,
    n_expected: Optional[int],
) -> List[dict]:
    # Normalize polarity so digits are dark on light background
    if np.mean(img_gray) < 127:
        working = cv2.bitwise_not(img_gray)
    else:
        working = img_gray.copy()

    if std_dev > 50:
        _, binary = cv2.threshold(
            working,
            0,
            255,
            cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU,
        )
    else:
        blur = cv2.GaussianBlur(working, (3, 3), 0)
        binary = cv2.adaptiveThreshold(
            blur,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV,
            15,
            5,
        )
        kernel = np.ones((2, 2), np.uint8)
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)
        binary = cv2.erode(binary, kernel, iterations=1)

    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    boxes = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w * h >= 60:
            boxes.append((x, y, w, h))
    boxes.sort(key=lambda b: b[0])

    if not boxes or (n_expected and len(boxes) != n_expected):
        return _fallback_projection_split(working, n_expected)

    results: List[dict] = []
    for (x, y, w, h) in boxes:
        roi = binary[y : y + h, x : x + w]
        proj = np.sum(roi, axis=0)
        if np.count_nonzero(proj == 0) == 0 and n_expected and len(boxes) < n_expected:
            extra = _projection_split_region(roi, x, y)
            results.extend(extra)
        else:
            results.append({
                "bbox": (x, y, w, h),
                "crop": _resize_and_center(roi, 28),
            })

    if n_expected and len(results) != n_expected:
        return _fallback_projection_split(working, n_expected)

    results.sort(key=lambda item: item["bbox"][0])
    return results


def _projection_split_region(roi: np.ndarray, x0: int, y0: int) -> List[dict]:
    proj = np.sum(roi, axis=0)
    mask = proj > proj.max() * 0.25
    regions = _find_contiguous_true_regions(mask)
    digits = []
    for (start, end) in regions:
        if end - start < 2:
            continue
        digit = roi[:, start:end]
        digits.append({
            "bbox": (x0 + start, y0, end - start, roi.shape[0]),
            "crop": _resize_and_center(digit, 28),
        })
    return digits


def _fallback_projection_split(img_gray: np.ndarray, n_expected: Optional[int]) -> List[dict]:
    _, binary = cv2.threshold(img_gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    projection = np.sum(binary, axis=0)
    smooth = np.convolve(projection, _gaussian_kernel1d(21, 4), mode="same")
    threshold = smooth.max() * 0.12
    mask = smooth > threshold
    regions = _find_contiguous_true_regions(mask)

    if n_expected and len(regions) < n_expected:
        regions = _split_big_regions(regions, binary.shape[1], n_expected)

    if n_expected and len(regions) != n_expected:
        step = max(1, binary.shape[1] // n_expected)
        regions = []
        for idx in range(n_expected):
            start = idx * step
            end = binary.shape[1] if idx == n_expected - 1 else (idx + 1) * step
            if end - start >= 2:
                regions.append((start, end))

    digits = []
    height = binary.shape[0]
    for (start, end) in regions:
        if end - start < 2:
            continue
        digit = binary[:, start:end]
        digits.append({
            "bbox": (start, 0, end - start, height),
            "crop": _resize_and_center(digit, 28),
        })
    digits.sort(key=lambda item: item["bbox"][0])
    return digits


def _gaussian_kernel1d(length: int, sigma: float) -> np.ndarray:
    if length % 2 == 0:
        length += 1
    half = length // 2
    x = np.arange(-half, half + 1)
    kernel = np.exp(-(x ** 2) / (2 * sigma * sigma))
    return kernel / kernel.sum()


def _find_contiguous_true_regions(mask: np.ndarray) -> List[Tuple[int, int]]:
    mask = mask.astype(np.int8)
    diff = np.diff(mask)
    starts = list(np.where(diff == 1)[0] + 1)
    ends = list(np.where(diff == -1)[0] + 1)
    if mask[0] == 1:
        starts.insert(0, 0)
    if mask[-1] == 1:
        ends.append(mask.size)
    return list(zip(starts, ends))


def _split_big_regions(
    regions: Sequence[Tuple[int, int]],
    width: int,
    expected: int,
    min_width: int = 5,
) -> List[Tuple[int, int]]:
    if not regions:
        return []
    regions = sorted(regions, key=lambda item: item[1] - item[0], reverse=True)
    output = list(regions)
    deficit = expected - len(output)
    if deficit <= 0:
        return sorted(output, key=lambda item: item[0])

    new_regions: List[Tuple[int, int]] = []
    for (start, end) in regions:
        span = end - start
        if span < min_width or deficit <= 0:
            new_regions.append((start, end))
            continue
        segments = min(deficit + 1, max(1, span // max(min_width, 1)))
        cursor = start
        for idx in range(segments):
            seg_start = cursor
            seg_end = end if idx == segments - 1 else cursor + max(1, span // segments)
            if seg_end - seg_start >= 2:
                new_regions.append((seg_start, seg_end))
            cursor = seg_end
        deficit -= max(0, segments - 1)

    if len(new_regions) < expected:
        step = max(1, width // expected)
        new_regions = []
        for idx in range(expected):
            seg_start = idx * step
            seg_end = width if idx == expected - 1 else (idx + 1) * step
            if seg_end - seg_start >= 2:
                new_regions.append((seg_start, seg_end))
    return sorted(new_regions, key=lambda item: item[0])


def _confidence_from_model(model, sample: np.ndarray) -> float:
    if hasattr(model, "decision_function"):
        score = float(np.max(model.decision_function(sample)))
        confidence = 1 / (1 + math.exp(-abs(score)))
        return round(confidence * 100, 2)
    if hasattr(model, "predict_proba"):
        proba = np.max(model.predict_proba(sample))
        return round(float(proba) * 100, 2)
    return 75.0
