#!/usr/bin/env bash
set -euo pipefail

# build_appimage.sh - Build StemWeaver AppImage
# Creates a self-contained AppImage with all dependencies

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP=StemWeaver
APPDIR="$REPO_ROOT/AppDir"
# Light variant: do NOT bundle Python runtime or models to keep releases small
APPIMAGE="$REPO_ROOT/StemWeaver-v1.1-x86_64-light.AppImage"

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
rsync -a --exclude='.git' --exclude='packaging' --exclude='*.AppImage' --exclude='AppDir' --exclude='venv' --exclude='myenv' --exclude='build' --exclude='build_new.log' --exclude='*.7z' --exclude='.history' --exclude='models' --exclude='*.md' --exclude='*.txt' . "$APPDIR/usr/share/stemweaver/"
# Light build: exclude heavy files and documentation (.md/.txt). Copy only allowed docs (README, CONTRIBUTING, requirements) into the AppDir so users still have access to essential info.
for f in README.md CONTRIBUTING.md requirements.txt; do
  if [ -f "$REPO_ROOT/$f" ]; then
    cp "$REPO_ROOT/$f" "$APPDIR/usr/share/stemweaver/"
    echo "Included: $f"
  fi
done

# Ensure scripts in the AppDir are executable
if [ -d "$APPDIR/usr/share/stemweaver/scripts" ]; then
  echo "Setting executable permission on bundled scripts..."
  find "$APPDIR/usr/share/stemweaver/scripts" -type f -name "*.sh" -exec chmod +x {} + || true
fi

# Create launcher script
cat > "$APPDIR/usr/bin/stemweaver" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(dirname "$(readlink -f "$0")")"
APPROOT="$HERE/../share/stemweaver"
USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/StemWeaver"
MODELS_DIR="$USER_DATA_DIR/models"

# Ensure user data directory exists
mkdir -p "$MODELS_DIR"

# Prefer system Python3
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python 3 is required but not found. Please install Python 3 or run $APPROOT/install_deps.sh" >&2
  exit 1
fi

# If dependencies missing, offer to run installer (non-interactive with AUTO_INSTALL=1)
if ! $PY -c "import dearpygui" >/dev/null 2>&1; then
  if [ "${AUTO_INSTALL:-0}" -eq 1 ] || [ "${CI:-0}" -eq 1 ]; then
    echo "Auto-installing Python dependencies..."
    "$APPROOT/install_deps.sh"
  else
    echo "Required Python packages not found (e.g., DearPyGui)."
    read -p "Install dependencies now into your user site (~200MB)? [y/N] " ans || ans="n"
    case "$ans" in
      y|Y|yes|Yes) "$APPROOT/install_deps.sh" ;;
      *) echo "You can run: $APPROOT/install_deps.sh"; exit 1 ;;
    esac
  fi
fi

# If no models present, offer to download recommended models
if [ -z "$(ls -A "$MODELS_DIR" 2>/dev/null || true)" ]; then
  echo "No models found in $MODELS_DIR." >&2
  if [ "${AUTO_INSTALL:-0}" -eq 1 ]; then
    echo "Auto-downloading recommended models..."
    "$APPROOT/scripts/download_models.sh" --all --yes || echo "Model download failed; continue anyway." >&2
  else
    echo "Recommended models are required for AI processing. This light AppImage can download them for you." >&2
    read -p "Download recommended models now? [y/N] " ans || ans="n"
    case "$ans" in
      y|Y|yes|Yes)
        "$APPROOT/scripts/download_models.sh" --all || echo "Model download failed; continue anyway." ;;
      *) echo "You can download models later with: $APPROOT/scripts/download_models.sh --all" ;;
    esac
  fi
fi

# Run the app
exec "$PY" "$APPROOT/gui_data/gui_modern_extractor.py" "$@"
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

# Light build: do NOT create a Python virtual environment or install dependencies
echo "Light build: not bundling Python runtime or models. Users must install Python 3 and required packages or run the included installer script."

# Create a lightweight installer script that users can run on their machine to install dependencies and download models
cat > "$APPDIR/usr/share/stemweaver/install_deps.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTDIR/../.." && pwd)"
REQ_FILE="$REPO_ROOT/requirements.txt"

if [ ! -f "$REQ_FILE" ]; then
  echo "Error: requirements.txt not found at $REQ_FILE"
  exit 1
fi

echo "Installing required Python packages into user site (python3 -m pip install --user -r requirements.txt)"
python3 -m pip install --user --upgrade pip setuptools wheel
python3 -m pip install --user -r "$REQ_FILE"

# Models download placeholder: instruct the user where to place models
echo ""
echo "=== Models setup ==="
echo "This light AppImage does not include AI models."
echo "Download required models from the project page and place them in:"
echo "  ~/.local/share/StemWeaver/models/"
echo "You can also use the full AppImage (hosted on SourceForge/Backblaze) which includes models bundled."

echo "Done. To run StemWeaver, ensure python3 is in your PATH and run:"
echo "  python3 "$REPO_ROOT"/gui_data/gui_modern_extractor.py"
EOF

chmod +x "$APPDIR/usr/share/stemweaver/install_deps.sh"

echo "Installer script written to: $APPDIR/usr/share/stemweaver/install_deps.sh"

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
