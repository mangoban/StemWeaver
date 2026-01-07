#!/usr/bin/env bash
set -euo pipefail

# Manjaro / Arch setup script for Universal Sound Extractor
# Run as a normal user; sudo will be used where necessary.

echo "Updating system and installing required system packages (pacman)..."
sudo pacman -Syu --noconfirm

# Essential build tools and Python support
sudo pacman -S --needed --noconfirm base-devel git pkgconf cmake python python-pip python-virtualenv tk

# Audio & multimedia dependencies
sudo pacman -S --needed --noconfirm ffmpeg rubberband libsndfile sox

# Optional: ALSA/Pulse/pipewire utilities (install as needed)
sudo pacman -S --needed --noconfirm alsa-utils pulseaudio pipewire

# Optional: install Rust toolchain for building some wheels (if you will build from source)
# sudo pacman -S --needed --noconfirm rust

cat <<'EOF'
Next steps (recommended):
1) Create and activate a virtual environment:

   python -m venv venv
   source venv/bin/activate

2) Upgrade pip, wheel, setuptools:

   pip install --upgrade pip setuptools wheel

3) Install Python requirements (CPU mode):

   pip install -r requirements-manjaro.txt

Note: For PyTorch and GPU support, install PyTorch per official instructions:
https://pytorch.org/get-started/locally/
Example CPU install:

   pip install "torch" torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

To install ONNX Runtime with CUDA (optional):
  Follow https://onnxruntime.ai/docs/build/ for the correct wheel matching your CUDA/cuDNN.

If any pip package fails to build, please install the missing system libs (e.g. libjpeg-turbo, zlib, libpng) via pacman and retry.
EOF

echo "Manjaro setup script finished."
