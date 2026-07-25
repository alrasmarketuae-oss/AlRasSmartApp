"""
CLIP embedding microservice for Al Ras Market.
Multilingual CLIP so Arabic + English product names share the same vector space.
"""
from __future__ import annotations

import io
import os
from typing import List

import numpy as np
import torch
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from PIL import Image
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

MODEL_NAME = os.getenv("CLIP_MODEL", "sentence-transformers/clip-ViT-B-32-multilingual-v1")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

app = FastAPI(title="Al Ras CLIP Service", version="1.0.0")
model = SentenceTransformer(MODEL_NAME, device=DEVICE)
VECTOR_DIM = int(model.get_sentence_embedding_dimension())


class TextEmbedRequest(BaseModel):
    text: str


class EmbedResponse(BaseModel):
    vector: List[float]
    dim: int
    model: str


def _normalize(vec: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(vec)
    if norm <= 1e-12:
        return vec
    return vec / norm


def _load_image(data: bytes) -> Image.Image:
    try:
        image = Image.open(io.BytesIO(data)).convert("RGB")
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}") from exc
    return image


def _center_crop(image: Image.Image, ratio: float = 0.75) -> Image.Image:
    """Keep the center of the image (product assumed centered); trim edge background."""
    ratio = max(0.4, min(1.0, float(ratio)))
    if ratio >= 0.999:
        return image
    w, h = image.size
    crop_w = max(1, int(round(w * ratio)))
    crop_h = max(1, int(round(h * ratio)))
    left = (w - crop_w) // 2
    top = (h - crop_h) // 2
    return image.crop((left, top, left + crop_w, top + crop_h))


def _embed_image(image: Image.Image) -> np.ndarray:
    focused = _center_crop(image, ratio=float(os.getenv("CLIP_CENTER_CROP_RATIO", "0.75")))
    vec = model.encode(focused, convert_to_numpy=True, normalize_embeddings=True)
    return _normalize(np.asarray(vec, dtype=np.float32))


def _embed_text(text: str) -> np.ndarray:
    cleaned = (text or "").strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail="text is required")
    vec = model.encode(cleaned, convert_to_numpy=True, normalize_embeddings=True)
    return _normalize(np.asarray(vec, dtype=np.float32))


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model": MODEL_NAME,
        "dim": VECTOR_DIM,
        "device": DEVICE,
    }


@app.post("/embed/image", response_model=EmbedResponse)
async def embed_image(file: UploadFile = File(...)):
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="empty file")
    vector = _embed_image(_load_image(data))
    return EmbedResponse(vector=vector.tolist(), dim=VECTOR_DIM, model=MODEL_NAME)


@app.post("/embed/text", response_model=EmbedResponse)
async def embed_text(body: TextEmbedRequest):
    vector = _embed_text(body.text)
    return EmbedResponse(vector=vector.tolist(), dim=VECTOR_DIM, model=MODEL_NAME)


@app.post("/embed/multimodal", response_model=EmbedResponse)
async def embed_multimodal(
    file: UploadFile = File(...),
    text: str = Form(...),
    image_weight: float = Form(0.7),
    text_weight: float = Form(0.3),
):
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="empty file")

    img_w = max(0.0, float(image_weight))
    txt_w = max(0.0, float(text_weight))
    total = img_w + txt_w
    if total <= 1e-9:
        img_w, txt_w, total = 0.7, 0.3, 1.0
    img_w /= total
    txt_w /= total

    image_vec = _embed_image(_load_image(data))
    text_vec = _embed_text(text)
    fused = _normalize((img_w * image_vec) + (txt_w * text_vec))
    return EmbedResponse(vector=fused.tolist(), dim=VECTOR_DIM, model=MODEL_NAME)
