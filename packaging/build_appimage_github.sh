#!/usr/bin/env bash
set -euo pipefail

# build_appimage_github.sh - GitHub Actions specific build script
# Uses only default paths, no custom temp directories

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP=StemWeaver
APPDIR="$REPO_ROOT/AppDir"
APPIMAGE="$REPO_ROOT/StemWeaver-v1.1-x86_64.AppImage"

# Ensure we're in the repository root for the build
cd "$REPO_ROOT"

# Use default temp directory (works in GitHub Actions)
export TMPDIR="/tmp/stemweaver_build"
mkdir -p "$TMPDIR"

echo "Building StemWeaver AppImage (GitHub Actions version)..."
echo "Script directory: $SCRIPT_DIR"
echo "Repository root: $REPO_ROOT"
echo "AppDir: $APPDIR"
echo "Temp directory: $TMPDIR"

# Clean previous build
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps" "$APPDIR/usr/share/stemweaver"

# Copy application files
echo "Copying application files..."
cd "$REPO_ROOT"
rsync -a --exclude='.git' --exclude='packaging' --exclude='*.AppImage' --exclude='AppDir' --exclude='myenv' --exclude='build' --exclude='build_new.log' --exclude='*.7z' --exclude='.history' --exclude='models/Demucs_Models/v3_v4_repo' --exclude='models/MDX_Net_Models/model_data' . "$APPDIR/usr/share/stemweaver/"

# Create launcher script
cat > "$APPDIR/usr/bin/stemweaver" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
PYHOME="$HERE/../share/stemweaver/venv"
export PYTHONPATH="$HERE/../share/stemweaver:$PYTHONPATH"
if [ -x "$PYHOME/bin/python" ]; then
  exec "$PYHOME/bin/python" "$HERE/../share/stemweaver/gui_data/gui_modern_extractor.py" "$@"
else
  exec python3 "$HERE/../share/stemweaver/gui_data/gui_modern_extractor.py" "$@"
fi
EOF
chmod +x "$APPDIR/usr/bin/stemweaver"

# Desktop file
cat > "$APPDIR/usr/share/applications/stemweaver.desktop" <<'EOF'
[Desktop Entry]
Name=StemWeaver
Comment=Professional Audio Stem Separation Tool
Exec=stemweaver
Icon=stemweaver
Type=Application
Categories=AudioVideo;Audio;
EOF

# Copy icon
cp "$REPO_ROOT/AppDir/stemweaver.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png"

# Create Python virtual environment
echo "Creating Python virtual environment..."
cd "$APPDIR/usr/share/stemweaver"
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install dependencies
echo "Installing dependencies from requirements.txt..."
pip install -r "$REPO_ROOT/requirements.txt"

# Install PyTorch CPU version (for AppImage compatibility)
echo "Installing PyTorch (CPU version)..."
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install ONNX Runtime
echo "Installing ONNX Runtime..."
pip install onnxruntime

# Install DearPyGui
echo "Installing DearPyGui..."
pip install dearpygui

# Deactivate venv
deactivate

echo "Virtual environment setup complete."

# Extract appimagetool to avoid FUSE issues
echo "Extracting appimagetool to avoid FUSE issues..."
cd "$SCRIPT_DIR/tools"
if [ -f "appimagetool-x86_64.AppImage" ]; then
    ./appimagetool-x86_64.AppImage --appimage-extract >/dev/null 2>&1
    APPIMAGETOOL="./squashfs-root/AppRun"
else
    echo "Error: appimagetool not found in $SCRIPT_DIR/tools"
    exit 1
fi

# Copy desktop file and icon to AppDir root for compatibility
echo "Copied desktop file to AppDir root for compatibility"
cp "$APPDIR/usr/share/applications/stemweaver.desktop" "$APPDIR/"
echo "Copied icon file to AppDir root for compatibility"
cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png" "$APPDIR/"

# Create AppImage
echo "Creating AppImage..."
cd "$REPO_ROOT"
"$APPIMAGETOOL" "$APPDIR" "$APPIMAGE"

# Make executable
chmod +x "$APPIMAGE"

echo "✅ AppImage created successfully: $APPIMAGE"
ls -lh "$APPIMAGE"
