#!/bin/bash
# Build Windows ZIP package (cross-platform)
# This creates a portable Windows package that can be run with Python

set -e

echo "=== Building Windows ZIP Package ==="

# Create build directory
BUILD_DIR="build/windows"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/StemWeaver"

echo "1. Copying application files..."
cp -r gui_data lib_v5 models "$BUILD_DIR/StemWeaver/"
cp requirements.txt "$BUILD_DIR/StemWeaver/"
cp README.md "$BUILD_DIR/StemWeaver/"
cp LICENSE "$BUILD_DIR/StemWeaver/"

echo "2. Creating Windows launcher..."
cat > "$BUILD_DIR/StemWeaver/StemWeaver.bat" << 'EOF'
@echo off
cd /d "%~dp0"
set PYTHONPATH=%CD%;%CD%\lib_v5;%CD%\gui_data

echo StemWeaver v1.1 - Windows Launcher
echo ===================================
echo.

if exist "venv\Scripts\python.exe" (
    echo Using virtual environment...
    "venv\Scripts\python.exe" "gui_data\gui_modern_extractor.py" %*
) else (
    echo Using system Python...
    python "gui_data\gui_modern_extractor.py" %*
)
EOF

echo "3. Creating setup instructions..."
cat > "$BUILD_DIR/StemWeaver/SETUP_WINDOWS.txt" << 'EOF'
StemWeaver for Windows - Setup Instructions
===========================================

Method 1: Using Python (Recommended)
------------------------------------
1. Install Python 3.10+ from python.org
2. Open Command Prompt
3. Navigate to this folder
4. Run: pip install -r requirements.txt
5. Run: StemWeaver.bat

Method 2: Using Virtual Environment
-----------------------------------
1. Open Command Prompt as Administrator
2. Navigate to this folder
3. Run: python -m venv venv
4. Run: venv\Scripts\activate
5. Run: pip install -r requirements.txt
6. Run: StemWeaver.bat

Method 3: Portable (No Installation)
-----------------------------------
1. Install Python 3.10+ and add to PATH
2. Run: pip install dearpygui torch torchaudio demucs librosa soundfile pretty_midi midiutil numpy scipy
3. Run: StemWeaver.bat

Requirements:
- Python 3.10 or newer
- 4GB RAM minimum
- 5GB disk space
- Internet connection for first run (downloads AI models)

Notes:
- First run will download AI models (~1-2GB)
- Models are cached for future use
- For GPU support, install CUDA toolkit

Support: https://github.com/mangoban/StemWeaver
EOF

echo "4. Creating README for Windows users..."
cat > "$BUILD_DIR/StemWeaver/README_WINDOWS.md" << 'EOF'
# StemWeaver for Windows

**Professional AI-powered audio stem separation tool**

## Quick Start

### Option 1: Using Python (Recommended)
1. Install Python 3.10+ from [python.org](https://python.org)
2. Open Command Prompt
3. Navigate to StemWeaver folder
4. Run: `pip install -r requirements.txt`
5. Run: `StemWeaver.bat`

### Option 2: Virtual Environment
```cmd
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
StemWeaver.bat
```

## Features

- 🤖 **AI-Powered**: Meta Demucs v4 models
- 🎵 **Multi-Stem**: Vocals, drums, bass, piano, guitar, other
- ⚡ **GPU Support**: CUDA acceleration
- 📦 **Portable**: No installation required
- 🎨 **Modern GUI**: DearPyGui interface
- 🎼 **MIDI Export**: Convert to MIDI files
- 🔊 **Denoising**: Clean audio artifacts

## Supported Formats

**Input**: MP3, WAV, FLAC, OGG, M4A, AAC  
**Output**: WAV, MIDI

## System Requirements

- **OS**: Windows 10/11
- **Python**: 3.10+
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 5GB + 2GB for models
- **GPU** (optional): NVIDIA CUDA

## First Run

1. Downloads AI models (~1-2GB)
2. Caches for future use
3. Requires internet connection

## License

CC-BY-4.0 - Attribution required

## Support

- GitHub: https://github.com/mangoban/StemWeaver
- Buy Me a Coffee: https://buymeacoffee.com/mangoban

---

**StemWeaver** - Professional Audio Stem Separation Tool
EOF

echo "5. Creating ZIP package..."
cd "$BUILD_DIR"
zip -r -q "StemWeaver-Windows-x64.zip" StemWeaver/
cd ../..

echo ""
echo "=== Build Complete ==="
echo "Windows ZIP: $BUILD_DIR/StemWeaver-Windows-x64.zip"
echo ""
echo "Size: $(du -h "$BUILD_DIR/StemWeaver-Windows-x64.zip" | cut -f1)"
echo ""
echo "To use:"
echo "1. Extract the ZIP file"
echo "2. Follow SETUP_WINDOWS.txt instructions"
echo "3. Run StemWeaver.bat"