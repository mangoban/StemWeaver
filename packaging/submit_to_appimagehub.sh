#!/bin/bash
# Script to prepare and submit StemWeaver to AppImageHub

set -e

echo "=== StemWeaver AppImageHub Submission ==="
echo ""

# Check if AppImage exists
if [ ! -f "StemWeaver_v1.1-x86_64.AppImage" ]; then
    echo "Error: AppImage not found in current directory"
    echo "Please run ./build_appimage.sh first"
    exit 1
fi

# Create submission directory
SUBMIT_DIR="appimagehub-submit"
mkdir -p "$SUBMIT_DIR"

echo "1. Creating submission files..."

# Copy AppImage
cp StemWeaver_v1.1-x86_64.AppImage "$SUBMIT_DIR/"

# Create README.md for AppImageHub
cat > "$SUBMIT_DIR/README.md" << 'EOF'
# StemWeaver

**Professional AI-powered audio stem separation tool**

[![StemWeaver](https://raw.githubusercontent.com/mangoban/StemWeaver/main/packaging/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.svg)](https://github.com/mangoban/StemWeaver)

## Description

StemWeaver is a powerful AI-driven audio stem separation tool that intelligently separates audio tracks into individual instrumental components. Using advanced Meta Demucs AI models, it can extract vocals, drums, bass, piano, guitar, and other instruments from any audio file.

Perfect for music producers, DJs, remixers, content creators, and audio professionals.

## Features

- 🤖 **AI-Powered**: Uses Meta Demucs v4 AI models
- 🎵 **Multi-Stem**: Extract vocals, drums, bass, piano, guitar, other
- ⚡ **GPU Support**: CUDA acceleration for faster processing
- 📦 **Portable**: Single file, no installation required
- 🎚️ **Quality Control**: Multiple quality presets
- 🎨 **Modern GUI**: Beautiful interface with DearPyGui
- 🎼 **MIDI Export**: Convert stems to MIDI files
- 🔊 **Denoising**: Clean up audio artifacts
- 📁 **Batch Processing**: Process multiple files at once

## Download

### Latest Release

**x86_64 (Intel/AMD 64-bit)**
```bash
wget https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/StemWeaver-v1.1-x86_64.AppImage
chmod +x StemWeaver-v1.1-x86_64.AppImage
./StemWeaver-v1.1-x86_64.AppImage
```

## Quick Start

1. **Download** the AppImage
2. **Make executable**: `chmod +x StemWeaver-*.AppImage`
3. **Run**: `./StemWeaver-*.AppImage`
4. **First run**: Will download AI models (~1-2GB, requires internet)

## System Requirements

- **OS**: Linux (any distribution)
- **Architecture**: x86_64
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 5GB for AppImage + 2GB for AI models
- **GPU** (optional): NVIDIA CUDA for faster processing

## Supported Formats

**Input**: MP3, WAV, FLAC, OGG, M4A, AAC  
**Output**: WAV (16-bit/44.1kHz), MIDI

## Usage

### GUI Mode (Default)
```bash
./StemWeaver-v1.1-x86_64.AppImage
```

### Command Line
```bash
# Process single file
./StemWeaver-v1.1-x86_64.AppImage --process /path/to/audio.mp3

# Process directory
./StemWeaver-v1.1-x86_64.AppImage --process-dir /path/to/audio/folder
```

## First Run Process

On first launch:
1. AppImage extracts to temporary directory
2. Downloads AI models (~1-2GB)
3. Caches models for future use
4. Ready to process audio

**Note**: Internet connection required for first run!

## License

**CC-BY-4.0** - Creative Commons Attribution 4.0 International

## Support & Links

- **Repository**: https://github.com/mangoban/StemWeaver
- **Buy Me a Coffee**: https://buymeacoffee.com/mangoban

## Credits

- **Creator**: bendeb creations
- **AI Models**: Meta Demucs
- **GUI**: DearPyGui
- **License**: CC-BY-4.0

---

**StemWeaver** - Professional Audio Stem Separation Tool
EOF

# Create appimagehub.yml
cat > "$SUBMIT_DIR/appimagehub.yml" << 'EOF'
# AppImageHub submission for StemWeaver
# Submit to: https://github.com/AppImage/appimage.github.io

name: StemWeaver
description: "Professional AI-powered audio stem separation tool using Meta Demucs models"
categories:
  - Audio
  - AudioVideo
  - Music
  - Production

links:
  website: https://github.com/mangoban/StemWeaver
  donate: https://buymeacoffee.com/mangoban

icons:
  - url: https://raw.githubusercontent.com/mangoban/StemWeaver/main/packaging/AppDir/usr/share/icons/hicolor/256x256/apps/stemweaver.svg
    size: 256x256

license: CC-BY-4.0

author:
  name: "bendeb creations"
  email: "contact@bendebcreations.com"

download:
  x86_64: https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/StemWeaver-v1.1-x86_64.AppImage

build:
  type: github-actions
  script: packaging/build_appimage.sh

features:
  - "AI-powered stem separation (vocals, drums, bass, piano, guitar, other)"
  - "Meta Demucs v4 models"
  - "GPU acceleration support (CUDA)"
  - "Batch processing"
  - "MIDI export"
  - "Denoising"
  - "Modern GUI with DearPyGui"
  - "Portable - no installation required"

notes: |
  StemWeaver is a professional audio stem separation tool that uses advanced AI models to extract individual instruments from audio files.
  
  Key features:
  - Multiple AI models (Demucs, MDX, VR networks)
  - Support for 4-stem and 6-stem separation
  - GPU acceleration with CUDA
  - Batch processing capabilities
  - MIDI export for melodic instruments
  - Post-processing denoising
  - Modern, intuitive GUI
  
  The AppImage is built using GitHub Actions and includes all necessary dependencies.
  
  First-time users will need to download AI models (~1-2GB) on first run, which requires an internet connection.
EOF

echo ""
echo "2. Submission files created in: $SUBMIT_DIR/"
echo ""
echo "3. Files created:"
ls -lh "$SUBMIT_DIR/"
echo ""
echo "=== NEXT STEPS ==="
echo ""
echo "1. Fork https://github.com/AppImage/appimage.github.io"
echo "2. Clone your fork: git clone https://github.com/YOUR_USERNAME/appimage.github.io"
echo "3. Copy files:"
echo "   cp $SUBMIT_DIR/* appimage.github.io/apps/stemweaver/"
echo "4. Create new directory: mkdir -p appimage.github.io/apps/stemweaver"
echo "5. Copy the AppImage and README.md into that directory"
echo "6. Commit and push to your fork"
echo "7. Create pull request to upstream"
echo ""
echo "For more info: https://github.com/AppImage/appimage.github.io/blob/master/CONTRIBUTING.md"
echo ""
echo "=== Submission Ready! ==="