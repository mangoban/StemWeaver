#!/bin/bash
# Build DEB package for StemWeaver

set -e

echo "Building StemWeaver DEB package..."

# Package details
PACKAGE_NAME="stemweaver"
VERSION="1.1.0"
ARCH="amd64"
MAINTAINER="bendeb creations <mangoban@users.noreply.github.com>"
DESCRIPTION="Professional Audio Stem Separation Tool using AI"

# Create build directory
BUILD_DIR="/tmp/${PACKAGE_NAME}_${VERSION}_${ARCH}"
mkdir -p ${BUILD_DIR}/DEBIAN
mkdir -p ${BUILD_DIR}/usr/bin
mkdir -p ${BUILD_DIR}/usr/share/applications
mkdir -p ${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps
mkdir -p ${BUILD_DIR}/usr/share/stemweaver

echo "Creating control file..."
cat > ${BUILD_DIR}/DEBIAN/control << CONTROL
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: sound
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Depends: python3, python3-pip, ffmpeg
Description: ${DESCRIPTION}
 StemWeaver is a professional AI-powered audio stem separation tool.
 It uses Meta Demucs to separate vocals, drums, bass, and instruments.
 .
 Features:
  - AI-powered stem separation
  - Modern GUI interface
  - CPU/GPU processing
  - Multiple extraction profiles
  - MP3/FLAC/OGG/WAV support
  - CC BY 4.0 license

CONTROL

echo "Creating post-install script..."
cat > ${BUILD_DIR}/DEBIAN/postinst << POSTINST
#!/bin/bash
set -e

# Install Python dependencies
pip3 install dearpygui torch torchaudio demucs librosa soundfile pretty_midi midiutil

# Make executable
chmod +x /usr/bin/stemweaver

# Update desktop database
update-desktop-database /usr/share/applications

echo "StemWeaver installed successfully!"
echo "Run with: stemweaver"
POSTINST

chmod 755 ${BUILD_DIR}/DEBIAN/postinst

echo "Copying files..."

# Copy the AppImage as the main binary
if [ -f "/home/bendeb/stemweaver/StemWeaver-v1.1-x86_64.AppImage" ]; then
    cp /home/bendeb/stemweaver/StemWeaver-v1.1-x86_64.AppImage ${BUILD_DIR}/usr/bin/stemweaver
    chmod 755 ${BUILD_DIR}/usr/bin/stemweaver
else
    echo "Warning: AppImage not found, creating wrapper script"
    cat > ${BUILD_DIR}/usr/bin/stemweaver << 'WRAPPER'
#!/bin/bash
cd /usr/share/stemweaver
python3 gui_data/gui_modern_extractor.py "$@"
WRAPPER
    chmod 755 ${BUILD_DIR}/usr/bin/stemweaver
fi

# Copy desktop file
cp /home/bendeb/stemweaver/packaging/ultimatevocalremovergui.desktop ${BUILD_DIR}/usr/share/applications/stemweaver.desktop

# Copy icons
if [ -f "/home/bendeb/stemweaver/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.png" ]; then
    cp /home/bendeb/stemweaver/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.png \
       ${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps/stemweaver.png
fi

# Copy source code (if not using AppImage)
if [ ! -f "/home/bendeb/stemweaver/StemWeaver-v1.1-x86_64.AppImage" ]; then
    cp -r /home/bendeb/stemweaver/gui_data ${BUILD_DIR}/usr/share/stemweaver/
    cp -r /home/bendeb/stemweaver/lib_v5 ${BUILD_DIR}/usr/share/stemweaver/
    cp /home/bendeb/stemweaver/requirements.txt ${BUILD_DIR}/usr/share/stemweaver/
fi

echo "Building DEB package..."
dpkg-deb --build ${BUILD_DIR} /home/bendeb/stemweaver/stemweaver_${VERSION}_${ARCH}.deb

echo ""
echo "✅ DEB package created: /home/bendeb/stemweaver/stemweaver_${VERSION}_${ARCH}.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i stemweaver_${VERSION}_${ARCH}.deb"
echo "  sudo apt-get -f install  # to fix dependencies"
echo ""
echo "To upload to GitHub:"
echo "  Go to https://github.com/mangoban/StemWeaver/releases"
echo "  Upload this .deb file as a release asset"
