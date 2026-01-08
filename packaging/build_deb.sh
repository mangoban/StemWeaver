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

# Working directory
cd /home/bendeb/stemweaver

# Create build directory
BUILD_DIR="/tmp/${PACKAGE_NAME}_${VERSION}_${ARCH}"
rm -rf "$BUILD_DIR"
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

# Check for AppImage
if [ -f "StemWeaver-v1.1-x86_64.AppImage" ]; then
    echo "Using AppImage..."
    cp StemWeaver-v1.1-x86_64.AppImage ${BUILD_DIR}/usr/bin/stemweaver
    chmod 755 ${BUILD_DIR}/usr/bin/stemweaver
    
    # Extract icon from AppImage if possible
    if [ -d "AppDir/usr/share/icons" ]; then
        cp AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.png \
           ${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps/ 2>/dev/null || true
    fi
else
    echo "AppImage not found, using source installation method..."
    
    # Copy source code
    cp -r gui_data ${BUILD_DIR}/usr/share/stemweaver/
    cp -r lib_v5 ${BUILD_DIR}/usr/share/stemweaver/
    cp -r models ${BUILD_DIR}/usr/share/stemweaver/
    cp requirements.txt ${BUILD_DIR}/usr/share/stemweaver/
    
    # Create wrapper script
    cat > ${BUILD_DIR}/usr/bin/stemweaver << 'WRAPPER'
#!/bin/bash
export PYTHONPATH="/usr/share/stemweaver:$PYTHONPATH"
cd /usr/share/stemweaver
exec python3 gui_data/gui_modern_extractor.py "$@"
WRAPPER
    chmod 755 ${BUILD_DIR}/usr/bin/stemweaver
    
    # Copy icon
    if [ -f "gui_data/img/stemweaver.png" ]; then
        cp gui_data/img/stemweaver.png \
           ${BUILD_DIR}/usr/share/icons/hicolor/256x256/apps/stemweaver.png
    fi
fi

# Create desktop file
cat > ${BUILD_DIR}/usr/share/applications/stemweaver.desktop << 'DESKTOP'
[Desktop Entry]
Name=StemWeaver
Comment=Professional Audio Stem Separation Tool
Exec=/usr/bin/stemweaver
Icon=stemweaver
Type=Application
Categories=Audio;AudioVideo;
Terminal=false
DESKTOP

# Create control file
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

# Create postinst script
cat > ${BUILD_DIR}/DEBIAN/postinst << 'POSTINST'
#!/bin/bash
set -e

echo "Installing StemWeaver dependencies..."
pip3 install --upgrade pip
pip3 install dearpygui==2.1.1 torch torchaudio demucs librosa soundfile pretty_midi midiutil numpy==2.3.5

# Make executable
chmod +x /usr/bin/stemweaver

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

echo ""
echo "✅ StemWeaver installed successfully!"
echo ""
echo "To run:"
echo "  stemweaver"
echo ""
echo "Or find it in your applications menu."
POSTINST

chmod 755 ${BUILD_DIR}/DEBIAN/postinst

# Build the package
echo "Building DEB package..."
dpkg-deb --build ${BUILD_DIR} stemweaver_${VERSION}_${ARCH}.deb

echo ""
echo "✅ DEB package created: stemweaver_${VERSION}_${ARCH}.deb"
ls -lh stemweaver_${VERSION}_${ARCH}.deb
