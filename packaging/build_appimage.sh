#!/usr/bin/env bash
set -euo pipefail

# build_appimage.sh - Build StemWeaver AppImage
# Creates a self-contained AppImage with all dependencies

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP=StemWeaver
APPDIR="$REPO_ROOT/AppDir"
APPIMAGE="$REPO_ROOT/StemWeaver-v1.1-x86_64.AppImage"

# Ensure we're in the repository root for the build
cd "$REPO_ROOT"

# Set larger temp directory to avoid space issues
# Use /tmp if /home/bendeb/build_temp is not accessible (e.g., in CI)
if [ -z "${TMPDIR:-}" ]; then
    # Try custom temp dir first, fallback to /tmp
    CUSTOM_TEMP="/home/bendeb/build_temp"
    if mkdir -p "$CUSTOM_TEMP" 2>/dev/null && [ -w "$CUSTOM_TEMP" ]; then
        export TMPDIR="$CUSTOM_TEMP"
    else
        export TMPDIR="/tmp/stemweaver_build"
        mkdir -p "$TMPDIR"
    fi
fi

echo "Building StemWeaver AppImage..."
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
Categories=Audio;AudioVideo;
Terminal=false
EOF

# Copy icon
if [ -f "$APPDIR/usr/share/stemweaver/gui_data/img/GUI-Icon.png" ]; then
  cp "$APPDIR/usr/share/stemweaver/gui_data/img/GUI-Icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png"
elif [ -f "gui_data/img/GUI-Icon.png" ]; then
  cp "gui_data/img/GUI-Icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png"
else
  echo "Warning: No icon found, AppImage will have no icon"
fi

# Create Python virtual environment
echo "Creating Python virtual environment..."
echo "Using Python: $(which python)"
python -m venv "$APPDIR/usr/share/stemweaver/venv"
source "$APPDIR/usr/share/stemweaver/venv/bin/activate"

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install dependencies
if [ -f "$REPO_ROOT/requirements.txt" ]; then
  echo "Installing from requirements.txt..."
  echo "Requirements file: $REPO_ROOT/requirements.txt"
  pip install -r "$REPO_ROOT/requirements.txt"
else
  echo "Error: requirements.txt not found at $REPO_ROOT/requirements.txt"
  echo "Current directory: $(pwd)"
  echo "REPO_ROOT: $REPO_ROOT"
  ls -la "$REPO_ROOT"
  exit 1
fi

# Install CPU-only PyTorch (required for Demucs)
echo "Installing PyTorch (CPU version)..."
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install ONNX Runtime (for VR models)
echo "Installing ONNX Runtime..."
pip install onnxruntime

# Install DearPyGui
echo "Installing DearPyGui..."
pip install dearpygui==2.1.1

deactivate
echo "Virtual environment setup complete."

# Download linuxdeploy if not present
TOOLS_DIR="$REPO_ROOT/packaging/tools"
mkdir -p "$TOOLS_DIR"

if [ ! -f "$TOOLS_DIR/linuxdeploy-x86_64.AppImage" ]; then
  echo "Downloading linuxdeploy..."
  wget -q -O "$TOOLS_DIR/linuxdeploy-x86_64.AppImage" \
    https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  chmod +x "$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
fi

if [ ! -f "$TOOLS_DIR/appimagetool-x86_64.AppImage" ]; then
  echo "Downloading appimagetool..."
  wget -q -O "$TOOLS_DIR/appimagetool-x86_64.AppImage" \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOLS_DIR/appimagetool-x86_64.AppImage"
fi

LINUXDEPLOY="$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
APPIMAGETOOL="$TOOLS_DIR/appimagetool-x86_64.AppImage"

# Make AppImage executable
chmod +x "$LINUXDEPLOY" "$APPIMAGETOOL"

# Extract appimagetool to avoid FUSE issues
if [ -f "$APPIMAGETOOL" ]; then
  echo "Extracting appimagetool to avoid FUSE issues..."
  cd "$TOOLS_DIR"
  if ! "$APPIMAGETOOL" --appimage-extract >/dev/null 2>&1; then
    echo "Extract failed, trying with --appimage-extract-and-run..."
    "$APPIMAGETOOL" --appimage-extract-and-run --appimage-extract >/dev/null 2>&1 || true
  fi
  cd "$REPO_ROOT"
  
  # Use extracted appimagetool if available
  if [ -f "$TOOLS_DIR/squashfs-root/AppRun" ]; then
    APPIMAGETOOL="$TOOLS_DIR/squashfs-root/AppRun"
    echo "Using extracted appimagetool: $APPIMAGETOOL"
  else
    echo "Using original appimagetool with extract-and-run"
  fi
fi

# Verify tools are executable
if [ ! -x "$APPIMAGETOOL" ]; then
  echo "Error: appimagetool is not executable"
  exit 1
fi

# Ensure we're back in the repo root
cd "$REPO_ROOT"

# Set AppRun for the AppDir
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export PYTHONPATH="$HERE/usr/share/stemweaver:$PYTHONPATH"
export PATH="$HERE/usr/bin:$PATH"
exec "$HERE/usr/bin/stemweaver" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Copy desktop file to AppDir root for extracted appimagetool compatibility
if [ -f "$APPDIR/usr/share/applications/stemweaver.desktop" ]; then
  cp "$APPDIR/usr/share/applications/stemweaver.desktop" "$APPDIR/"
  echo "Copied desktop file to AppDir root for compatibility"
fi

# Copy icon file to AppDir root for extracted appimagetool compatibility
if [ -f "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png" ]; then
  cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png" "$APPDIR/"
  echo "Copied icon file to AppDir root for compatibility"
elif [ -f "$APPDIR/usr/share/stemweaver/gui_data/img/GUI-Icon.png" ]; then
  cp "$APPDIR/usr/share/stemweaver/gui_data/img/GUI-Icon.png" "$APPDIR/stemweaver.png"
  echo "Copied icon file from gui_data to AppDir root for compatibility"
fi

# Create AppImage using appimagetool
echo "Creating AppImage..."
cd "$APPDIR"

# Use the appropriate appimagetool approach
if [ -x "$APPIMAGETOOL" ]; then
  if [ "$APPIMAGETOOL" = "$TOOLS_DIR/squashfs-root/AppRun" ]; then
    echo "Using extracted appimagetool..."
    "$APPIMAGETOOL" . "$APPIMAGE"
  else
    echo "Using appimagetool with extract-and-run..."
    # Try with extract-and-run first, fallback to normal if that fails
    if ! "$APPIMAGETOOL" --appimage-extract-and-run . "$APPIMAGE" 2>/dev/null; then
      echo "Extract-and-run failed, trying normal mode..."
      "$APPIMAGETOOL" . "$APPIMAGE"
    fi
  fi
else
  echo "Error: appimagetool not found or not executable"
  exit 1
fi

cd "$REPO_ROOT"

# Verify AppImage was created successfully
if [ -f "$APPIMAGE" ]; then
  echo "✅ AppImage created successfully: $APPIMAGE"
  ls -lh "$APPIMAGE"
else
  echo "❌ AppImage creation failed"
  exit 1
fi
