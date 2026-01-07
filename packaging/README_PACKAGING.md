Packaging notes for Manjaro/Arch and AppImage

This directory contains templates and helper scripts to create a Manjaro package (PKGBUILD) and an AppImage for the UVR fork.

1) PKGBUILD (AUR/package)
- The provided `PKGBUILD` is a template. Steps to use:
  - Create a source tarball of the repo: `git archive --format=tar.gz -o ultimatevocalremovergui-5.6.0.tar.gz HEAD`
  - Move the tarball into this folder and edit the `source`/`sha256sums` in `PKGBUILD`.
  - Build the package:

    ```bash
    makepkg -si
    ```

- The template installs the project under `/opt/ultimatevocalremovergui` and creates an `/usr/bin/uvr` launcher that prefers a bundled virtualenv if present.
- The PKGBUILD lists runtime dependencies (python, ffmpeg, rubberband, libsndfile, tk). Adjust `depends` as needed.

2) AppImage (cross-distro)
- Creating a reliable AppImage for a Python+PyTorch app requires bundling all Python wheels and native libs. Recommended approach:
  - Use `linuxdeploy` + `linuxdeploy-plugin-pyqt`/`linuxdeploy-plugin-python`, or use `pynsist`/`shiv` alternatives.
  - Provided script `build_appimage.sh` attempts to use linuxdeploy and appimagetool. You need to install them first.

3) Scripts included
- `build_appimage.sh` - helper script to create an AppDir and build an AppImage (requires `linuxdeploy`, `appimagetool`, and linuxdeploy python plugin). Edit the variables to match paths.
- `PKGBUILD` - template for creating an Arch package.

4) Limitations and notes
- PyTorch and GPU libraries are large and sensitive to CUDA versions. For AppImage you will generally bundle CPU-only wheels or provide GPU instructions separately.
- The AppImage approach below prefers bundling a pre-built Python wheel set into the AppDir. If you want me to attempt a full AppImage build in your environment, I can run the script and iterate on fixes.

5) Next steps I can take for you
- Build the AUR package locally (run `makepkg`) and iterate.
- Attempt to build a working AppImage in your environment (I'll need to install linuxdeploy/appimagetool or use their downloadable binaries).

If you want me to proceed, tell me which you prefer: build PKGBUILD package, build AppImage, or both. Also confirm whether you want the package to include a bundled Python virtualenv (so it works on systems without network) or rely on system Python and pip installs.