# GitHub Packages & Releases Guide

## 🎯 What You Want

You want to **build packages on GitHub's servers** (not locally) and distribute them through GitHub Releases.

## ✅ What I've Set Up

### 1. **GitHub Actions Workflows**

Two workflows created in `.github/workflows/`:

#### **A. Automatic Release Builder** (`build_packages.yml`)
- **Triggers:** When you push a tag like `v1.1.0`
- **What it does:**
  1. Builds AppImage on GitHub server
  2. Builds DEB package on GitHub server
  3. Builds RPM package on GitHub server
  4. Builds Arch package on GitHub server
  5. Creates a GitHub Release
  6. Uploads all packages as release assets

#### **B. Manual Builder** (`build_packages_manual.yml`)
- **Triggers:** You manually run it from GitHub Actions tab
- **What it does:**
  1. Builds all packages
  2. Uploads them as downloadable artifacts
  3. You can download and test before creating a release

---

## 🚀 How to Use (Step-by-Step)

### Method 1: Automatic (Recommended)

**Step 1: Push your code**
```bash
cd /home/bendeb/stemweaver
git add .
git commit -m "Ready for v1.1.0 release"
git push origin main
```

**Step 2: Create and push a tag**
```bash
git tag -a v1.1.0 -m "StemWeaver v1.1.0 - Initial release"
git push origin v1.1.0
```

**Step 3: GitHub Actions takes over!**
- ✅ Automatically builds all packages
- ✅ Creates a release
- ✅ Uploads everything

**Step 4: View your release**
Go to: https://github.com/mangoban/StemWeaver/releases

---

### Method 2: Manual (Test First)

**Step 1: Go to GitHub Actions tab**
- Visit: https://github.com/mangoban/StemWeaver/actions
- Click on "Build Packages (Manual)"
- Click "Run workflow"
- Enter version: `v1.1.0`

**Step 2: Wait for build to complete**
- Takes 5-10 minutes
- All packages built on GitHub servers

**Step 3: Download artifacts**
- Go to the workflow run
- Download the `all-packages-v1.1.0` artifact
- Test the packages locally

**Step 4: If everything works, create a release**
```bash
git tag -a v1.1.0 -m "StemWeaver v1.1.0"
git push origin v1.1.0
```
- This will trigger the automatic release workflow
- Or manually create a release and upload the tested packages

---

## 📦 What Gets Built

When the workflow runs, you get:

| Package | File | For | Size |
|---------|------|-----|------|
| **AppImage** | `StemWeaver-v1.1-x86_64.AppImage` | All Linux | ~50MB |
| **DEB** | `stemweaver_1.1.0_amd64.deb` | Debian/Ubuntu | ~50MB |
| **RPM** | `stemweaver-1.1.0-1.x86_64.rpm` | Fedora/RHEL | ~50MB |
| **Arch** | `stemweaver-1.1.0-1-x86_64.pkg.tar.zst` | Arch/Manjaro | ~50MB |

---

## 🎯 Your Current Status

### ✅ Already Done:
- [x] Source code on GitHub
- [x] All packaging scripts created
- [x] GitHub Actions workflows created
- [x] AppImage already built locally

### ⏳ Next Steps:
1. **Commit the workflows:**
   ```bash
   git add .github/workflows/
   git commit -m "Add GitHub Actions for automatic packaging"
   git push origin main
   ```

2. **Create a release:**
   ```bash
   git tag -a v1.1.0 -m "StemWeaver v1.1.0"
   git push origin v1.1.0
   ```

3. **Wait 5-10 minutes** for GitHub to build everything

4. **Check your release:** https://github.com/mangoban/StemWeaver/releases

---

## 🔧 What If Workflows Fail?

### Common Issues:

**1. AppImage build fails**
- Check: `packaging/build_appimage.sh` has correct paths
- Solution: Update paths in the script

**2. DEB/RPM build fails**
- Check: Your build scripts use correct file paths
- Solution: The scripts already use relative paths, should work

**3. Release creation fails**
- Check: You have the right permissions
- Solution: Make sure you're the repo owner

### Debug Mode:
Run workflows manually and check logs in GitHub Actions tab.

---

## 📊 GitHub Packages vs GitHub Releases

### GitHub Releases (What You Want) ✅
- **Best for:** Desktop applications
- **How:** Upload files to a release
- **User downloads:** Direct download links
- **Example:** https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/StemWeaver-v1.1-x86_64.AppImage

### GitHub Packages (Alternative)
- **Best for:** Libraries, containers, npm packages
- **How:** Package registry with versioning
- **User installs:** `pip install`, `docker pull`, etc.
- **Not needed for:** Desktop apps like StemWeaver

---

## 🎉 After Release

Your users can install StemWeaver with:

**Universal:**
```bash
wget https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/StemWeaver-v1.1-x86_64.AppImage
chmod +x StemWeaver-v1.1-x86_64.AppImage
./StemWeaver-v1.1-x86_64.AppImage
```

**Debian/Ubuntu:**
```bash
wget https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/stemweaver_1.1.0_amd64.deb
sudo dpkg -i stemweaver_1.1.0_amd64.deb
sudo apt-get -f install
```

**Fedora/RHEL:**
```bash
sudo dnf install https://github.com/mangoban/StemWeaver/releases/download/v1.1.0/stemweaver-1.1.0-1.x86_64.rpm
```

---

## 🚀 Ready to Start?

**Just do this:**

```bash
cd /home/bendeb/stemweaver

# Commit the workflows
git add .github/workflows/
git commit -m "Add GitHub Actions packaging workflows"
git push origin main

# Create release tag
git tag -a v1.1.0 -m "StemWeaver v1.1.0"
git push origin v1.1.0

# Then wait and watch GitHub build everything!
```

**Go to:** https://github.com/mangoban/StemWeaver/actions to see the progress!

---

**Need help?** The workflows are already configured. Just push the tag and let GitHub do the work! 🎵
