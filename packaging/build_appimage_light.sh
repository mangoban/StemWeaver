#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPDIR="$REPO_ROOT/AppDir"
TOOLS_DIR="$REPO_ROOT/packaging/tools"

# Prepare AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy app code (exclude large model files)
rsync -a --exclude='.git' --exclude='packaging' --exclude='models' . "$APPDIR/usr/share/stemweaver/"

# Create launcher
cat > "$APPDIR/usr/bin/stemweaver" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
PYHOME="$HERE/../share/stemweaver/venv"
if [ -d "$PYHOME" ]; then
  exec "$PYHOME/bin/python" "$HERE/../share/stemweaver/gui_data/gui_modern_extractor.py" "$@"
else
  exec python "$HERE/../share/stemweaver/gui_data/gui_modern_extractor.py" "$@"
fi
EOF
chmod +x "$APPDIR/usr/bin/stemweaver"

# Desktop file
cat > "$APPDIR/usr/share/applications/stemweaver.desktop" <<'EOF'
[Desktop Entry]
Name=StemWeaver (Light)
Exec=stemweaver
Icon=stemweaver
Type=Application
Categories=Audio;AudioVideo;
EOF

# Create a small venv and install light deps
PYTHON="/home/bendeb/.pyenv/versions/3.11.9/bin/python3.11"
if [ ! -x "$PYTHON" ]; then
  PYTHON=python3
fi
$PYTHON -m venv "$APPDIR/usr/share/stemweaver/venv"
source "$APPDIR/usr/share/stemweaver/venv/bin/activate"
python -m pip install --upgrade pip setuptools wheel
pip install -r "$REPO_ROOT/packaging/requirements-light.txt"
deactivate

# Copy icon if available
if [ -f "$REPO_ROOT/gui_data/img/StemWeaver.png" ]; then
  cp "$REPO_ROOT/gui_data/img/StemWeaver.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stemweaver.png"
fi

# Run linuxdeploy to create AppImage using local tools if available
LINUXDEPLOY="$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
APPIMAGETOOL="$TOOLS_DIR/appimagetool-x86_64.AppImage"

if [ ! -x "$LINUXDEPLOY" ]; then
  echo "linuxdeploy not found at $LINUXDEPLOY; ensure you downloaded tools or have linuxdeploy in PATH"
  exit 1
fi
if [ ! -x "$APPIMAGETOOL" ]; then
  echo "appimagetool not found at $APPIMAGETOOL; ensure you downloaded tools or have appimagetool in PATH"
  exit 1
fi

# Make linuxdeploy executable
chmod +x "$LINUXDEPLOY"
chmod +x "$APPIMAGETOOL"

# Run linuxdeploy and produce AppImage. Some linuxdeploy AppImage builds don't
# support the --appimage-extract-and-run flag, so try the standard output mode
# first and fall back to calling appimagetool directly if needed.
if "$LINUXDEPLOY" --appdir "$APPDIR" --output appimage; then
  echo "linuxdeploy completed (check for AppImage in the current directory)."
else
  echo "linuxdeploy failed to produce an AppImage; falling back to appimagetool..."
  # appimagetool will create an AppImage from the AppDir
  "$APPIMAGETOOL" "$APPDIR"
fi

echo "Lightweight AppImage build finished. Check for an AppImage in the current directory or the build output above for errors."
