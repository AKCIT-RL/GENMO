# ─────────────────────────────────────────────────────────────────────────────
# GENMO — GENeralist Model for Human MOtion
# Base: CUDA 12.1 + cuDNN 8 (compatible with torch==2.3.0+cu121)
# ─────────────────────────────────────────────────────────────────────────────
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    # Python 3.10
    python3.10 python3.10-dev python3.10-distutils python3-pip python3-tk \
    # Video codecs
    ffmpeg \
    # OpenCV / OpenGL (headless)
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender1 \
    # Build tools (cython_bbox, lapx)
    build-essential \
    libgomp1 \
    # Utilities
    git wget curl \
    && rm -rf /var/lib/apt/lists/*

# Set python3.10 as default
RUN update-alternatives --install /usr/bin/python  python  /usr/bin/python3.10 1 \
 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
 && update-alternatives --install /usr/bin/pip     pip     /usr/bin/pip3       1

WORKDIR /app

# ── Python dependencies (separate layer for build cache) ─────────────────────
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel \
 && pip install chumpy --no-build-isolation \
 && pip install -r requirements.txt

# ── Source code (large data excluded via .dockerignore) ──────────────────────
COPY . .

# ── Install GENMO and GVHMR packages ─────────────────────────────────────────
# --no-deps: dependencies already installed via requirements.txt
RUN pip install -e . --no-deps
RUN pip install -e third_party/GVHMR --no-deps

# ── Runtime directories (populated via bind mounts in compose) ────────────────
RUN mkdir -p outputs inputs/checkpoints

# ── PYTHONPATH: include project root and GVHMR ───────────────────────────────
ENV PYTHONPATH="/app:/app/third_party/GVHMR"

# Note: dynamic camera mode (--no-static-cam / SLAM) requires DPVO compiled inside the image.
# By default the pipeline uses static_cam=true, which does not require DPVO.

WORKDIR /app
