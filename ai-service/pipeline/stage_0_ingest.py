"""
pipeline/stage_0_ingest.py
---------------------------
STUB — Phase 2

Receives a signed image URL from Supabase Storage.
Downloads the raw bytes and determines the document type (image vs PDF).

Phase 1: not wired. Returns a placeholder RawDocument.
Phase 2: use httpx to fetch the signed URL, detect mime type, return bytes.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class RawDocument:
    bill_id: str
    image_url: str
    raw_bytes: bytes | None = None
    mime_type: str = "image/jpeg"
    page_count: int = 1


def ingest(bill_id: str, image_url: str) -> RawDocument:
    """
    Phase 1 stub — does not download anything.
    TODO Phase 2: fetch image_url with httpx, detect mime, return bytes.
    """
    return RawDocument(bill_id=bill_id, image_url=image_url)
