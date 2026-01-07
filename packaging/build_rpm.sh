#!/bin/bash
# Build RPM package for StemWeaver

set -e

echo "Building StemWeaver RPM package..."

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
if [ -f /home/bendeb/stemweaver/StemWeaver-v1.1-x86_64.AppImage ]; then
    install -m 755 /home/bendeb/stemweaver/StemWeaver-v1.1-x86_64.AppImage %{buildroot}/usr/bin/stemweaver
else
    # Install source code
    cp -r /home/bendeb/stemweaver/gui_data %{buildroot}/usr/share/stemweaver/
    cp -r /home/bendeb/stemweaver/lib_v5 %{buildroot}/usr/share/stemweaver/
    cp /home/bendeb/stemweaver/requirements.txt %{buildroot}/usr/share/stemweaver/
    
    # Create wrapper
    cat > %{buildroot}/usr/bin/stemweaver << 'WRAPPER'
#!/bin/bash
cd /usr/share/stemweaver
python3 gui_data/gui_modern_extractor.py "$@"
WRAPPER
    chmod 755 %{buildroot}/usr/bin/stemweaver
fi

# Install desktop file
install -m 644 /home/bendeb/stemweaver/packaging/ultimatevocalremovergui.desktop \
    %{buildroot}/usr/share/applications/stemweaver.desktop

# Install icon
if [ -f /home/bendeb/stemweaver/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.png ]; then
    install -m 644 /home/bendeb/stemweaver/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.png \
        %{buildroot}/usr/share/icons/hicolor/256x256/apps/stemweaver.png
fi

%post
# Install Python dependencies
pip3 install dearpygui torch torchaudio demucs librosa soundfile pretty_midi midiutil 2>/dev/null || true

# Update desktop database
/usr/bin/update-desktop-database /usr/share/applications 2>/dev/null || true

echo "StemWeaver installed successfully!"
echo "Run with: stemweaver"

%files
%defattr(-,root,root,-)
/usr/bin/stemweaver
/usr/share/applications/stemweaver.desktop
/usr/share/icons/hicolor/256x256/apps/stemweaver.png
/usr/share/stemweaver/

%changelog
* Tue Jan 08 2026 bendeb creations <mangoban@users.noreply.github.com> - 1.1.0-1
- Initial release of StemWeaver
- AI-powered stem separation
- Modern GUI interface
- CC BY 4.0 license

SPEC

echo "Building RPM package..."
rpmbuild -bb ~/rpmbuild/SPECS/stemweaver.spec

# Copy the built RPM
RPM_FILE=$(find ~/rpmbuild/RPMS -name "stemweaver-${VERSION}-${RELEASE}*.rpm" -type f)
if [ -f "$RPM_FILE" ]; then
    cp "$RPM_FILE" /home/bendeb/stemweaver/
    echo ""
    echo "✅ RPM package created: /home/bendeb/stemweaver/$(basename $RPM_FILE)"
    echo ""
    echo "To install:"
    echo "  sudo rpm -i $(basename $RPM_FILE)"
    echo "  sudo dnf install $(basename $RPM_FILE)  # Fedora/RHEL"
    echo ""
    echo "To upload to GitHub:"
    echo "  Go to https://github.com/mangoban/StemWeaver/releases"
    echo "  Upload this .rpm file as a release asset"
else
    echo "❌ RPM build failed"
    exit 1
fi
