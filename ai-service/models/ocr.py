"""
models/ocr.py
--------------
OCR model interface + PaddleOCR default implementation.
Not wired to the pipeline in Phase 1 — import is guarded so the
service starts without PaddleOCR installed.

To install PaddleOCR:
  pip install paddlepaddle paddleocr
  # or for CPU-only:
  pip install paddlepaddle-cpu paddleocr
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field


@dataclass
class OcrWord:
    text: str
    confidence: float
    bbox: dict  # {x, y, w, h, page}


@dataclass
class OcrOutput:
    full_text: str
    words: list[OcrWord] = field(default_factory=list)
    engine: str = "unknown"


class OcrModel(ABC):
    @abstractmethod
    def extract(self, image_bytes: bytes) -> OcrOutput:
        ...


class PaddleOcrModel(OcrModel):
    """
    PaddleOCR wrapper. Lazy-loaded so the service starts without it installed.
    Phase 2: instantiate this in stage_1_ocr.py.
    """

    def __init__(self) -> None:
        # Lazy import — PaddleOCR is not installed in Phase 1
        try:
            from paddleocr import PaddleOCR  # type: ignore
            self._paddle = PaddleOCR(use_angle_cls=True, lang="en", show_log=False)
        except ImportError:
            self._paddle = None

    def extract(self, image_bytes: bytes) -> OcrOutput:
        if self._paddle is None:
            raise RuntimeError(
                "PaddleOCR is not installed. "
                "Run: pip install paddlepaddle-cpu paddleocr"
            )
        import tempfile, os
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f:
            f.write(image_bytes)
            tmp_path = f.name

        try:
            result = self._paddle.ocr(tmp_path, cls=True)
        finally:
            os.unlink(tmp_path)

        words: list[OcrWord] = []
        full_lines: list[str] = []

        for page in (result or []):
            for item in (page or []):
                bbox_raw, (text, conf) = item
                xs = [pt[0] for pt in bbox_raw]
                ys = [pt[1] for pt in bbox_raw]
                words.append(OcrWord(
                    text=text,
                    confidence=conf,
                    bbox={
                        "x": min(xs), "y": min(ys),
                        "w": max(xs) - min(xs),
                        "h": max(ys) - min(ys),
                        "page": 0,
                    },
                ))
                full_lines.append(text)

        return OcrOutput(
            full_text="\n".join(full_lines),
            words=words,
            engine="paddleocr",
        )
