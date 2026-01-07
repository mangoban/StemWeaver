#!/usr/bin/env bash
set -euo pipefail

# build_appimage.sh - minimal script to produce an AppImage using linuxdeploy
# Requirements (install or download): linuxdeploy, appimagetool, linuxdeploy-plugin-python
# This is a template and likely needs tuning for PyTorch apps.

APP=UltimateVocalRemover
APPDIR=AppDir
APPIMAGE=UltimateVocalRemover.AppImage

if [ ! -d "$APPDIR" ]; then
  mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
fi

# Copy code into AppDir (you can choose to copy only necessary files)
rsync -a --exclude='.git' --exclude='packaging' . "$APPDIR/usr/share/ultimatevocalremovergui/"

# create a launcher script
cat > "$APPDIR/usr/bin/uvr" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
PYHOME="$HERE/../share/ultimatevocalremovergui/venv"
if [ -x "$PYHOME/bin/python" ]; then
  exec "$PYHOME/bin/python" "$HERE/../share/ultimatevocalremovergui/UVR.py" "$@"
else
  exec python "$HERE/../share/ultimatevocalremovergui/UVR.py" "$@"
fi
EOF
chmod +x "$APPDIR/usr/bin/uvr"

# desktop file
cat > "$APPDIR/usr/share/applications/universal_sound_extractor.desktop" <<'EOF'
[Desktop Entry]
Name=Universal Sound Extractor
Exec=uvr
Icon=universal_sound_extractor
Type=Application
Categories=Audio;AudioVideo;
EOF

# copy icon if present
if [ -f gui_data/img/UVR_v5.6.png ]; then
  cp gui_data/img/UVR_v5.6.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/universal_sound_extractor.png"
fi

PYENV_PYTHON="$HOME/.pyenv/versions/3.11.9/bin/python3.11"
if [ -x "$PYENV_PYTHON" ]; then
  echo "Using pyenv python: $PYENV_PYTHON to create venv"
  "$PYENV_PYTHON" -m venv "$APPDIR/usr/share/universal_sound_extractor/venv"
else
  # Fallback to system python
  python -m venv "$APPDIR/usr/share/universal_sound_extractor/venv"
fi
source "$APPDIR/usr/share/universal_sound_extractor/venv/bin/activate"
pip install --upgrade pip setuptools wheel
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$REPO_ROOT/requirements-manjaro.txt" ]; then
  REQFILE="$REPO_ROOT/requirements-manjaro.txt"
elif [ -f "$REPO_ROOT/requirements.txt" ]; then
  REQFILE="$REPO_ROOT/requirements.txt"
else
  echo "No requirements file found in repo root. Exiting."
  exit 1
fi
pip install -r "$REQFILE"
# Install CPU-only PyTorch and ONNX Runtime into the AppDir venv to make a full, self-contained AppImage.
# WARNING: these packages are large (torch wheels are multiple GB) and the install can take a long time.
pip install "torch" torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install onnxruntime
# note: Installing torch inside AppImage may be large and slow. If you want GPU-enabled wheels, install matching CUDA wheels manually.
deactivate

# Use linuxdeploy to bundle runtime libraries and create AppImage
# You must have linuxdeploy and appimagetool in PATH, or download their binaries and adjust path here.

TOOLS_DIR="$REPO_ROOT/packaging/tools"
if [ -f "$TOOLS_DIR/linuxdeploy-x86_64.AppImage" ]; then
  LINUXDEPLOY="$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
else
  LINUXDEPLOY="linuxdeploy"
fi
if [ -f "$TOOLS_DIR/appimagetool-x86_64.AppImage" ]; then
  APPIMAGETOOL="$TOOLS_DIR/appimagetool-x86_64.AppImage"
else
  APPIMAGETOOL="appimagetool"
fi

if ! command -v "$LINUXDEPLOY" >/dev/null 2>&1 && [ "$LINUXDEPLOY" = "linuxdeploy" ]; then
  echo "linuxdeploy not found in PATH and no local copy available. Install or download it: https://github.com/linuxdeploy/linuxdeploy"
  exit 1
fi
if ! command -v "$APPIMAGETOOL" >/dev/null 2>&1 && [ "$APPIMAGETOOL" = "appimagetool" ]; then
  echo "appimagetool not found in PATH and no local copy available. Install or download it: https://github.com/AppImage/AppImageKit/releases"
  exit 1
fi

# run linuxdeploy (this will inspect AppDir and bundle libs)
"$LINUXDEPLOY" --appdir "$APPDIR" --output appimage --appimage-extract-and-run "$APPIMAGETOOL" || \
"$LINUXDEPLOY" --appdir "$APPDIR" --output appimage

echo "If linuxdeploy succeeded, you should have an AppImage in the current directory."
