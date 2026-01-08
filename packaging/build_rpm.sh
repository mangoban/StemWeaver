#!/bin/bash
# Build RPM package for StemWeaver

set -e

echo "Building StemWeaver RPM package..."

# Working directory
cd /home/bendeb/stemweaver

# Package details
PACKAGE_NAME="stemweaver"
VERSION="1.1.0"
RELEASE="1"
ARCH="x86_64"
SUMMARY="Professional Audio Stem Separation Tool using AI"
LICENSE="CC-BY-4.0"
URL="https://github.com/mangoban/StemWeaver"
VENDOR="bendeb creations"
DESCRIPTION="Professional AI-powered audio stem separation tool using Meta Demucs"

# Check for required tools
if ! command -v rpmbuild &> /dev/null; then
    echo "Error: rpmbuild not found. Install with: sudo dnf install rpm-build"
    exit 1
fi

# Create RPM build structure
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create spec file
cat > ~/rpmbuild/SPECS/stemweaver.spec << SPEC
Name:           ${PACKAGE_NAME}
Version:        ${VERSION}
Release:        ${RELEASE}
Summary:        ${SUMMARY}
License:        ${LICENSE}
URL:            ${URL}
Vendor:         ${VENDOR}
BuildArch:      ${ARCH}
Requires:       python3, python3-pip, ffmpeg

%description
${DESCRIPTION}

Features:
- AI-powered stem separation using Meta Demucs
- Modern GUI interface with theme support
- CPU/GPU processing (CUDA for NVIDIA)
- Multiple extraction profiles (6-stem, 4-stem, vocals-only)
- Quality settings 1-5
- MP3/FLAC/OGG/WAV support with auto-conversion
- MIDI export capability
- Real-time progress feedback

%prep
# No source to unpack

%build
# No build step needed

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps
mkdir -p %{buildroot}/usr/share/stemweaver

# Install AppImage or source
if [ -f StemWeaver-v1.1-x86_64.AppImage ]; then
    install -m 755 StemWeaver-v1.1-x86_64.AppImage %{buildroot}/usr/bin/stemweaver
else
    # Install source code
    cp -r gui_data %{buildroot}/usr/share/stemweaver/
    cp -r lib_v5 %{buildroot}/usr/share/stemweaver/
    cp -r models %{buildroot}/usr/share/stemweaver/
    cp requirements.txt %{buildroot}/usr/share/stemweaver/
    
    # Create wrapper
    cat > %{buildroot}/usr/bin/stemweaver << 'WRAPPER'
#!/bin/bash
export PYTHONPATH="/usr/share/stemweaver:$PYTHONPATH"
cd /usr/share/stemweaver
exec python3 gui_data/gui_modern_extractor.py "$@"
WRAPPER
    chmod 755 %{buildroot}/usr/bin/stemweaver
fi

# Install desktop file
cat > %{buildroot}/usr/share/applications/stemweaver.desktop << 'DESKTOP'
[Desktop Entry]
Name=StemWeaver
Comment=Professional Audio Stem Separation Tool
Exec=/usr/bin/stemweaver
Icon=stemweaver
Type=Application
Categories=Audio;AudioVideo;
Terminal=false
DESKTOP

# Install icon
if [ -f gui_data/img/stemweaver.png ]; then
    install -m 644 gui_data/img/stemweaver.png \
        %{buildroot}/usr/share/icons/hicolor/256x256/apps/stemweaver.png
fi

%post
# Install Python dependencies
pip3 install --upgrade pip 2>/dev/null || true
pip3 install dearpygui==2.1.1 torch torchaudio demucs librosa soundfile pretty_midi midiutil numpy==2.3.5 2>/dev/null || true

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

echo ""
echo "✅ StemWeaver installed successfully!"
echo ""
echo "To run:"
echo "  stemweaver"

%files
%defattr(-,root,root,-)
/usr/bin/stemweaver
/usr/share/applications/stemweaver.desktop
/usr/share/icons/hicolor/256x256/apps/stemweaver.png
/usr/share/stemweaver/

%changelog
* Tue Jan 08 2026 bendeb creations <mangoban@users.noreply.github.com> - 1.1.0-1
- Initial release of StemWeaver
- AI-powered stem separation using Meta Demucs
- Modern GUI interface with 5 themes
- CPU/GPU processing support
- MIDI export capability
- CC BY 4.0 license

SPEC

echo "Building RPM package..."
cd ~/rpmbuild/SPECS
rpmbuild -bb stemweaver.spec

# Copy the built RPM
RPM_FILE=$(find ~/rpmbuild/RPMS -name "stemweaver-${VERSION}-${RELEASE}*.rpm" -type f | head -1)
if [ -f "$RPM_FILE" ]; then
    cd /home/bendeb/stemweaver
    cp "$RPM_FILE" ./
    RPM_NAME=$(basename "$RPM_FILE")
    echo ""
    echo "✅ RPM package created: $RPM_NAME"
    ls -lh "$RPM_NAME"
    echo ""
    echo "To install:"
    echo "  sudo dnf install $RPM_NAME"
    echo "  sudo rpm -i $RPM_NAME"
else
    echo "❌ RPM build failed"
    exit 1
fi
