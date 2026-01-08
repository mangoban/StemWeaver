#!/usr/bin/env bash
set -euo pipefail

# build_arch.sh - Build Arch Linux package for StemWeaver
# Creates a .pkg.tar.zst package for Arch/Manjaro

echo "=== StemWeaver Arch/Manjaro Package Builder ==="

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Check if running on Arch/Manjaro
if ! command -v pacman &> /dev/null; then
    echo "Error: This script must be run on Arch Linux or Manjaro"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run as root. makepkg will handle privileges."
    exit 1
fi

# Install required dependencies
echo "Installing build dependencies..."
sudo pacman -S --needed --noconfirm base-devel git python python-pip ffmpeg

# Create build directory
BUILD_DIR="build/arch"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Copy appropriate PKGBUILD
if [ "$ARCH" = "x86_64" ]; then
    PKGBUILD_FILE="../../packaging/PKGBUILD"
elif [ "$ARCH" = "aarch64" ]; then
    PKGBUILD_FILE="../../packaging/PKGBUILD.manjaro"
else
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

if [ ! -f "$PKGBUILD_FILE" ]; then
    echo "Error: $PKGBUILD_FILE not found"
    exit 1
fi

cp "$PKGBUILD_FILE" PKGBUILD

# Download source
echo "Downloading source..."
PKGVER=$(grep "^pkgver=" PKGBUILD | cut -d= -f2)
wget -q "https://github.com/mangoban/StemWeaver/archive/refs/tags/v${PKGVER}.tar.gz" -O "v${PKGVER}.tar.gz"

# Build package
echo "Building package..."
makepkg -si --noconfirm

# Find and move package
PKG_FILE=$(find . -name "*.pkg.tar.zst" -type f | head -1)
if [ -n "$PKG_FILE" ]; then
    cd ../..
    mv "build/arch/$PKG_FILE" ./
    echo ""
    echo "=== Build Complete ==="
    echo "Package: $PKG_FILE"
    echo ""
    echo "To install:"
    echo "  sudo pacman -U $PKG_FILE"
    echo ""
    echo "To publish to AUR:"
    echo "  1. Update PKGBUILD version"
    echo "  2. Run: makepkg --printsrcinfo > .SRCINFO"
    echo "  3. Commit to AUR repository"
else
    echo "❌ Package build failed"
    exit 1
fi