# StemWeaver Build & Release Instructions

This document explains how to build StemWeaver for multiple platforms and create releases.

## 🚀 Quick Start - Automated Builds

### GitHub Actions (Recommended)

**For Automated Releases:**
1. Push a tag to GitHub:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

2. GitHub Actions will automatically:
   - Build AppImage for x86_64 and aarch64
   - Build Windows ZIP and Installer
   - Build Arch Linux package
   - Create a GitHub Release with all artifacts

**For Manual Trigger:**
- Go to GitHub → Actions → "Build StemWeaver - All Platforms"
- Click "Run workflow"

## 📦 Platform-Specific Builds

### 1. AppImage (Linux - x86_64 & aarch64)

**Automated (GitHub Actions):**
- Workflow: `.github/workflows/build_all.yml`
- Artifacts: `StemWeaver-x86_64.AppImage`, `StemWeaver-aarch64.AppImage`

**Manual Build:**
```bash
cd packaging
./build_appimage.sh
```

**Requirements:**
- Linux with FUSE support
- Python 3.10+
- 4GB RAM
- 5GB disk space

### 2. Windows Package

**Automated (GitHub Actions):**
- Workflow: `.github/workflows/build_all.yml`
- Artifacts: `StemWeaver-Windows-x64.zip`, `StemWeaver-Windows-x64-Setup.exe`

**Manual Build (PowerShell):**
```powershell
cd packaging
.\build_windows.ps1
```

**Requirements:**
- Windows 10/11
- Python 3.10+ (from python.org)
- PowerShell 5.1+
- NSIS (optional, for installer)
- 4GB RAM
- 5GB disk space

**Output:**
- `StemWeaver-Windows-x64.zip` - Portable version
- `StemWeaver-Windows-x64-Setup.exe` - NSIS installer

### 3. Arch Linux / Manjaro Package

**Automated (GitHub Actions):**
- Workflow: `.github/workflows/build_all.yml`
- Artifact: `stemweaver-1.1.0-1-x86_64.pkg.tar.zst`

**Manual Build:**
```bash
cd packaging
./build_arch.sh
```

**Requirements:**
- Arch Linux or Manjaro
- `base-devel` package group
- `python`, `python-pip`, `ffmpeg`

**Output:**
- `stemweaver-1.1.0-1-x86_64.pkg.tar.zst` - Package file

**Installation:**
```bash
sudo pacman -U stemweaver-*.pkg.tar.zst
```

### 4. AUR Publishing

**For AUR (Arch User Repository):**
```bash
# 1. Update PKGBUILD version
# 2. Generate .SRCINFO
cd packaging
makepkg --printsrcinfo > .SRCINFO

# 3. Copy to AUR repository
# 4. Commit and push
git add PKGBUILD .SRCINFO
git commit -m "Update to v1.1.0"
git push
```

## 🔄 GitHub Actions Workflows

### Workflow Files

1. **`.github/workflows/build_all.yml`**
   - Triggered by: Tags (v*), Manual dispatch
   - Builds: All platforms
   - Creates: GitHub Release

2. **`.github/workflows/build_main.yml`**
   - Triggered by: Push to main
   - Builds: AppImage only
   - Uploads: Artifact (7 days retention)

3. **`.github/workflows/build_arch.yml`**
   - Triggered by: Tags (v*), Manual dispatch
   - Builds: Arch package
   - Uploads: Package artifact

### Environment Variables

**For Windows builds:**
- `PYTHON_VERSION`: 3.11
- `NSIS_REQUIRED`: true

**For Linux builds:**
- `PYTHON_VERSION`: 3.10
- `FUSE_SUPPORT`: true

## 📋 Build Requirements Summary

| Platform | Requirements | Output | Size |
|----------|--------------|--------|------|
| **AppImage x86_64** | Linux, Python, FUSE | `.AppImage` | ~4GB |
| **AppImage aarch64** | ARM Linux, Python, FUSE | `.AppImage` | ~4GB |
| **Windows** | Windows, Python, NSIS | `.zip`, `.exe` | ~4GB |
| **Arch Linux** | Arch/Manjaro, makepkg | `.pkg.tar.zst` | ~4GB |

## 🎯 Release Process

### Step 1: Prepare Release
```bash
# Update version in code
# Update CHANGELOG.md
# Update README.md if needed

# Commit changes
git add -A
git commit -m "Release v1.1.0"
git push origin main
```

### Step 2: Create Tag
```bash
git tag v1.1.0
git push origin v1.1.0
```

### Step 3: Wait for Automation
- GitHub Actions will build all platforms
- Artifacts will be uploaded
- Release will be created automatically

### Step 4: Verify Release
- Check GitHub Releases page
- Download and test artifacts
- Update release notes if needed

## 🔧 Manual Testing

### Test AppImage
```bash
chmod +x StemWeaver-*.AppImage
./StemWeaver-*.AppImage
```

### Test Windows Package
```powershell
# ZIP version
Expand-Archive -Path StemWeaver-Windows-x64.zip -DestinationPath .\StemWeaver
.\StemWeaver\StemWeaver.bat

# Installer version
.\StemWeaver-Windows-x64-Setup.exe
```

### Test Arch Package
```bash
sudo pacman -U stemweaver-*.pkg.tar.zst
stemweaver
```

## 📝 Troubleshooting

### AppImage won't run
```bash
# Check FUSE
lsmod | grep fuse

# Install FUSE if missing
sudo apt-get install fuse  # Debian/Ubuntu
sudo pacman -S fuse        # Arch
```

### Windows build fails
- Ensure Python is in PATH
- Run PowerShell as Administrator
- Install NSIS for installer creation

### Arch build fails
- Update system: `sudo pacman -Syu`
- Install base-devel: `sudo pacman -S base-devel`
- Check PKGBUILD syntax

## 🚢 Continuous Integration

### GitHub Packages
The workflows can also publish to GitHub Packages:
- Docker containers
- NuGet packages (for Windows)
- Container images

### Alternative Package Managers
- **Flatpak**: Create `org.stemweaver.StemWeaver.flatpak`
- **Snap**: Create `stemweaver.snap`
- **Debian**: Create `.deb` package
- **RPM**: Create `.rpm` package

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AppImage Documentation](https://docs.appimage.org/)
- [NSIS Documentation](https://nsis.sourceforge.io/Docs/)
- [Arch Package Guidelines](https://wiki.archlinux.org/title/Package_guidelines)

---

**Last Updated:** 2026-01-09
**Maintainer:** bendeb creations