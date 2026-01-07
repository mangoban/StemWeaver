#!/usr/bin/env bash
set -euo pipefail

TOOLS_DIR="$(pwd)/tools"
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR"

# Download linuxdeploy (appImage) and appimagetool
# Latest releases can be large; these are common locations.

if [ ! -f linuxdeploy-x86_64.AppImage ]; then
  echo "Downloading linuxdeploy..."
  curl -L -o linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  chmod +x linuxdeploy-x86_64.AppImage
fi

if [ ! -f appimagetool-x86_64.AppImage ]; then
  echo "Downloading appimagetool..."
  curl -L -o appimagetool-x86_64.AppImage https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
fi

# linuxdeploy-plugin-python (downloaded as a plugin .so or script depending on release)
# We'll use pip install in the build script to ensure plugin availability for linuxdeploy.

echo "Tools downloaded into $TOOLS_DIR"
