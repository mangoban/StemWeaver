#!/usr/bin/env bash
set -euo pipefail

# build_arch.sh - Build Arch Linux package for StemWeaver
# Creates a .pkg.tar.zst package for Arch/Manjaro

echo "Building StemWeaver Arch Linux package..."

# Check if AppImage exists
if [ ! -f "StemWeaver-v1.1-x86_64.AppImage" ]; then
  echo "Error: AppImage not found. Run build_appimage.sh first."
  exit 1
fi

# Create build directory
BUILD_DIR="arch_build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/pkg"

# Extract AppImage to get contents
echo "Extracting AppImage..."
./StemWeaver-v1.1-x86_64.AppImage --appimage-extract-and-run --appimage-extract -d "$BUILD_DIR/extracted" 2>/dev/null || true

# If extraction failed, use a different approach
if [ ! -d "$BUILD_DIR/extracted" ]; then
  echo "Using alternative packaging method..."
  mkdir -p "$BUILD_DIR/pkg/usr/bin"
  mkdir -p "$BUILD_DIR/pkg/usr/share/applications"
  mkdir -p "$BUILD_DIR/pkg/usr/share/icons/hicolor/256x256/apps"
  mkdir -p "$BUILD_DIR/pkg/usr/share/stemweaver"
  
  # Copy AppImage as the main binary
  cp StemWeaver-v1.1-x86_64.AppImage "$BUILD_DIR/pkg/usr/bin/stemweaver"
  chmod 755 "$BUILD_DIR/pkg/usr/bin/stemweaver"
  
  # Create desktop file
  cat > "$BUILD_DIR/pkg/usr/share/applications/stemweaver.desktop" <<'EOF'
[Desktop Entry]
Name=StemWeaver
Comment=Professional Audio Stem Separation Tool
Exec=/usr/bin/stemweaver
Icon=stemweaver
Type=Application
Categories=Audio;AudioVideo;
Terminal=false
EOF

  # Copy icon if available
  if [ -f "gui_data/img/stemweaver.png" ]; then
    cp "gui_data/img/stemweaver.png" "$BUILD_DIR/pkg/usr/share/icons/hicolor/256x256/apps/stemweaver.png"
  fi
else
  # Use extracted contents
  mkdir -p "$BUILD_DIR/pkg/usr"
  cp -r "$BUILD_DIR/extracted/squashfs-root/usr/"* "$BUILD_DIR/pkg/usr/" 2>/dev/null || true
  
  # Ensure bin directory exists
  mkdir -p "$BUILD_DIR/pkg/usr/bin"
  if [ -f "$BUILD_DIR/pkg/usr/bin/stemweaver" ]; then
    chmod 755 "$BUILD_DIR/pkg/usr/bin/stemweaver"
  fi
fi

# Create PKGBUILD
cat > "$BUILD_DIR/PKGBUILD" <<'EOF'
pkgname=stemweaver
pkgver=1.1.0
pkgrel=1
pkgdesc="Professional Audio Stem Separation Tool using AI"
arch=(x86_64)
url="https://github.com/mangoban/StemWeaver"
license=('CC BY 4.0')
depends=()
optdepends=('ffmpeg: for audio format support')
install=stemweaver.install
source=()
sha256sums=()

package() {
  cd "$srcdir/pkg"
  cp -r * "$pkgdir/"
}
EOF

# Create install file
cat > "$BUILD_DIR/stemweaver.install" <<'EOF'
post_install() {
  echo "StemWeaver installed successfully!"
  echo "Run 'stemweaver' to start the application."
  echo ""
  echo "Note: This package includes all Python dependencies."
  echo "No additional setup required."
}

post_upgrade() {
  post_install
}
EOF

# Build the package
cd "$BUILD_DIR"
echo "Building package with makepkg..."
makepkg -c --syncdeps --noconfirm

# Find and move the package
PKG_FILE=$(find . -name "*.pkg.tar.zst" -type f | head -1)
if [ -n "$PKG_FILE" ]; then
  cd ..
  mv "$BUILD_DIR/$PKG_FILE" ./
  echo "✅ Arch package created: $PKG_FILE"
  ls -lh "$PKG_FILE"
else
  echo "❌ Package build failed"
  exit 1
fi