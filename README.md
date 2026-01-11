# 🎵 StemWeaver v1.1

**Professional Audio Stem Separation Tool**

*Created by bendeb creations © 2026*

![alt text](image.png)

---

## Overview

**StemWeaver** is a powerful AI-driven audio stem separation tool that intelligently separates audio tracks into individual instrumental components. Using advanced Meta Demucs AI models, it can extract vocals, drums, bass, piano, guitar, and other instruments from any audio file.

Perfect for music producers, DJs, remixers, content creators, and audio professionals.

---

## ✨ Key Features

- 🤖 **AI-Powered**: Uses Meta Demucs (htdemucs_6s, htdemucs, mdx_extra, mdx_q)
- 🎚️ **4 Extraction Profiles**: 6-stem, 4-stem, vocals-only, instruments-only
- 🎯 **Vocal-first pipeline**: Optional vocal-first extraction (detects strong vocals and recommends running a vocal→accompaniment→instrument pipeline for cleaner instrument stems)
- 🎧 **Accompaniment-only export**: Save an accompaniment file with vocals removed (useful for backing tracks)
- 📊 **Quality Control**: 24-bit and 32-bit audio presets
- 🖥️ **Modern GUI**: Beautiful, intuitive interface with real-time feedback
- 💻 **GPU Support**: CUDA acceleration for faster processing
- 📦 **Portable**: Universal Linux AppImage - works on any distribution
- 🔒 **Open License**: Creative Commons Attribution 4.0 with proper attribution

---

## 🎯 What Makes StemWeaver Unique

StemWeaver is **not just another Demucs GUI wrapper**. It includes several innovative features that set it apart from similar projects:

### **Vocal-First Pipeline**
- **Two-stage separation**: Performs vocal/accompaniment separation first, then separates instruments from the accompaniment
- **Reduces vocal bleed**: Minimizes vocal artifacts in instrument stems for cleaner results
- **Auto-recommendation**: Analyzes audio and automatically suggests vocal-first processing when vocals are prominent
- **Smart detection**: Uses audio analysis to detect vocal strength and recommend the best approach

### **Multiple AI Model Support**
- **Demucs models**: htdemucs_ft, htdemucs_6s for balanced and high-quality separation
- **MDX-Net models**: Advanced neural networks for specific instrument isolation
- **VR (Vocal Remover) models**: Specialized models for vocal extraction
- **Model selection**: Choose the best AI model based on your audio content

### **Smart Audio Analysis**
- **Automatic model recommendation**: Analyzes your track and suggests the optimal AI model
- **Vocal strength detection**: Identifies prominent vocals and recommends processing strategies
- **Quality assessment**: Provides insights into audio characteristics for better results

### **Professional Features**
- **Accompaniment-only export**: Save backing tracks with vocals completely removed
- **Quality presets**: 24-bit and 32-bit audio processing options
- **Modern GUI**: Professional interface with real-time feedback and progress tracking
- **Batch processing**: Handle multiple files efficiently
- **Organized output**: Structured folder system with metadata

### **Technical Advantages**
- **Multi-model architecture**: Combines different AI approaches for better results
- **Adaptive processing**: Adjusts separation strategy based on audio content
- **Quality optimization**: Multiple quality levels for different use cases
- **Cross-platform compatibility**: Linux AppImage works on any distribution

**Unlike basic GUI wrappers for Demucs, StemWeaver provides an intelligent, multi-stage separation system that adapts to your audio content for professional-quality results.**

---

## 🚀 Quick Start

### Using AppImage (Recommended for Users)

```bash
# Make executable
chmod +x StemWeaver-v1.1-x86_64.AppImage

# Run
./StemWeaver-v1.1-x86_64.AppImage
```

### Building from Source (Easy Method)

```bash
# Clone the repository
git clone https://github.com/mangoban/StemWeaver.git
cd StemWeaver

# Run interactive build script
./build.sh
```

This will present you with multiple build options:
- **Option 1:** AppImage (x86_64) - Recommended for most Linux users
- **Option 2:** AppImage (ARM64) - For ARM-based systems
- **Option 3:** Arch Linux Package - For Arch/Manjaro
- **Option 4:** Development Environment - For developers
- **Option 5:** Build ALL packages

See [BUILD_GUIDE.md](docs/BUILD_GUIDE.md) for detailed instructions.

### Manual Installation (Advanced)

```bash
# Install dependencies (Manjaro/Arch)
sudo pacman -S python-pip ffmpeg

# Install Python packages
pip install dearpygui torch torchaudio demucs librosa soundfile pretty_midi midiutil

# Run from source
python gui_data/gui_modern_extractor.py
```

---

## 📋 System Requirements

- **OS**: Linux x86_64 (Manjaro, Ubuntu, Fedora, Debian, etc.)
- **RAM**: 8GB minimum (16GB+ for 6-stem processing)
- **Storage**: ~400MB for app + models
- **GPU** (optional): NVIDIA GPU with CUDA support
- **CPU**: Multi-core processor recommended

---



## ⚡ Performance

### GPU Processing Times (NVIDIA CUDA)
- 6-Stem: 2-3 minutes per song
- 4-Stem: 1-2 minutes per song
- Vocals Only: 1 minute per song

### CPU Processing Times
- 6-Stem: 5-10 minutes per song
- 4-Stem: 3-5 minutes per song
- Vocals Only: 2-3 minutes per song

---

## 📦 What's Included

- **AI Models**: Demucs 6-stem and 4-stem separation models
- **Modern GUI**: Professional interface with real-time feedback
- **Output Manager**: Organized folder structure with metadata
- **Multiple Presets**: Quality and extraction profile options
- **AppImage Package**: Self-contained, runs anywhere on Linux

## 📁 Project Structure

```
StemWeaver/
├── README.md                 # Main documentation
├── LICENSE                   # Creative Commons 4.0 license
├── AppDir/                   # AppImage build directory
├── gui_data/                 # GUI source code and assets
│   ├── gui_modern_extractor.py  # Main GUI application
│   ├── icons.py              # Icon definitions
│   ├── ui_styling.py         # UI theming
│   └── fonts/                # Font files
├── lib_v5/                   # AI model libraries
│   ├── mdxnet.py            # MDX-Net implementation
│   ├── tfc_tdf_v3.py        # Demucs model components
│   └── vr_network/          # VR network models
├── models/                   # Pre-trained AI models
│   ├── Demucs_Models/       # Demucs models
│   └── MDX_Net_Models/      # MDX-Net models
├── packaging/                # Packaging scripts
│   ├── PKGBUILD             # Arch Linux package
│   └── build_appimage.sh    # AppImage builder
├── scripts/                  # Installation scripts
├── docs/                     # All documentation files
└── dev/                      # Development tools and logs
```

---

## 🙏 Credits & Attribution

**StemWeaver v1.1** is developed by **bendeb creations** and licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

### Key Contributors
- **bendeb creations** - Developer, designer, and maintainer
- **Meta AI Research** - Demucs audio separation technology
- **PyTorch Community** - Deep learning framework
- **Open Source Community** - Libraries and tools

### Support the Project
If you find StemWeaver useful, consider supporting development:
- **Buy Me a Coffee**: https://buymeacoffee.com/mangoban
- **GitHub**: https://github.com/mangoban/StemWeaver

### When Using StemWeaver, Please Include:
```
StemWeaver v1.1 by bendeb creations
Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0)
```

---

## 📄 License

**Creative Commons Attribution 4.0 International (CC BY 4.0)**

### 🎯 ONE LICENSE - CC BY 4.0

This project uses **ONE consistent license** throughout:
- **License**: Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Copyright**: bendeb creations © 2026
- **Repository**: https://github.com/mangoban/StemWeaver

### ✅ What You CAN Do:
- Use for **any purpose** (commercial or personal)
- **Modify** and improve the software
- **Distribute** to others
- **Build upon** for your own projects
- **Sell** products made with StemWeaver

### ⚠️ What You MUST Do:
- **Give clear credit** to "bendeb creations"
- **Include this license** with any distribution
- **State changes** if you modify the software
- **Link back** to the original project

### 📝 Proper Attribution Format:

When using StemWeaver, you **MUST** include this notice:

```
StemWeaver v1.1 by bendeb creations
Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0)
Original project: https://github.com/mangoban/StemWeaver
```

### 💚 Support Development:

**bendeb creations** develops and maintains this project. If you find it useful:

- **Buy Me a Coffee**: https://buymeacoffee.com/mangoban
- **GitHub**: https://github.com/mangoban/StemWeaver
- **Share**: Tell others about StemWeaver

### 📜 Legal:

For the complete license text, see [LICENSE](LICENSE)

**Questions about licensing?** Contact bendeb creations or see the CONTRIBUTING.md file.

---

## 🎯 Use Cases

- Music production and remixing
- DJ and live performance
- Karaoke creation
- Audio analysis and research
- Sample pack creation
- Accessibility (instrumental versions)
- Music education

---

## 🔗 Resources

- **Project Repository**: https://github.com/mangoban/StemWeaver
- **Demucs GitHub**: https://github.com/facebookresearch/demucs
- **Creative Commons License**: https://creativecommons.org/licenses/by/4.0/
- **Support**: https://buymeacoffee.com/mangoban
- **PyTorch**: https://pytorch.org/
- **AppImage**: https://appimage.org/

---

## 📞 Support

For issues, suggestions, or questions:
- **Developer**: bendeb creations
- **Email**: contact@bendebcreations.com
- **License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

---

## 🛠️ Development

### Building the AppImage

```bash
cd packaging
./build_appimage.sh
```

This creates `StemWeaver-v1.1-x86_64.AppImage` in the root directory.

### Arch Linux Package

```bash
cd packaging
makepkg -si PKGBUILD
```

### Python Development

```bash
# Create virtual environment
python -m venv myenv
source myenv/bin/activate

# Install dependencies
pip install -r requirements.txt  # (create this file if needed)

# Run development version
python gui_data/gui_modern_extractor.py
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📊 Version History

### v1.1.0 - January 6, 2026
- ✅ AI-powered multi-stem audio separation
- ✅ 4 extraction profiles for different use cases
- ✅ Modern professional GUI interface
- ✅ GPU acceleration support (CUDA)
- ✅ Universal Linux AppImage distribution
- ✅ Creative Commons Attribution 4.0 licensing
- ✅ Comprehensive documentation

---

**StemWeaver v1.1**  
*Professional Audio Stem Separation*  
*By bendeb creations*  
© 2026 - Licensed under CC BY 4.0

---

🎵 Extract. Create. Inspire.

If you'd like, I can now build and test the `PKGBUILD` locally or attempt an AppImage build. Tell me which and whether to bundle a Python virtualenv in the package.
