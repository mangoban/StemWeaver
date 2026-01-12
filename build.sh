#!/bin/bash

################################################################################
# StemWeaver Build Script - Interactive Multi-Version Builder
# Supports: AppImage (x86_64, ARM64), Arch Linux Package, Source Installation
# Usage: ./build.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_LOG_DIR="$SCRIPT_DIR/.build_logs"
mkdir -p "$BUILD_LOG_DIR"

# Build timestamp
BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

################################################################################
# Utility Functions
################################################################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           StemWeaver v1.1 - Build System                       ║"
    echo "║        Professional Audio Stem Separation Tool                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    local missing_deps=()
    local optional_deps=()
    
    # Required dependencies
    local required=("python3" "pip" "git")
    for dep in "${required[@]}"; do
        if command_exists "$dep"; then
            print_success "$dep is installed"
        else
            missing_deps+=("$dep")
            print_error "$dep is NOT installed"
        fi
    done
    
    # Optional but recommended
    local optional=("ffmpeg" "gcc" "make")
    for dep in "${optional[@]}"; do
        if command_exists "$dep"; then
            print_success "$dep is installed (optional)"
        else
            optional_deps+=("$dep")
            print_warning "$dep is NOT installed (optional but recommended)"
        fi
    done
    
    # Check Python version
    if command_exists python3; then
        local py_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        print_info "Python version: $py_version"
        # Compare version numbers properly (3.8 <= version)
        local py_major=$(echo "$py_version" | cut -d. -f1)
        local py_minor=$(echo "$py_version" | cut -d. -f2)
        if [ "$py_major" -lt 3 ] || ([ "$py_major" -eq 3 ] && [ "$py_minor" -lt 8 ]); then
            print_error "Python 3.8+ is required (found $py_version)"
            missing_deps+=("python3.8+")
        fi
    fi
    
    # If there are missing required dependencies, offer to install
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "\nMissing required dependencies: ${missing_deps[*]}"
        echo ""
        read -p "Would you like to install missing dependencies? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies "${missing_deps[@]}"
        else
            print_error "Cannot proceed without required dependencies"
            return 1
        fi
    fi
    
    return 0
}

# Install dependencies based on system
install_dependencies() {
    local deps=("$@")
    
    if command_exists pacman; then
        print_info "Detected Arch Linux/Manjaro - using pacman"
        sudo pacman -Syu
        sudo pacman -S "${deps[@]}" --noconfirm
    elif command_exists apt-get; then
        print_info "Detected Debian/Ubuntu - using apt-get"
        sudo apt-get update
        sudo apt-get install -y "${deps[@]}"
    elif command_exists yum; then
        print_info "Detected RHEL/CentOS - using yum"
        sudo yum install -y "${deps[@]}"
    else
        print_error "Could not detect package manager. Please install dependencies manually:"
        printf '%s\n' "${deps[@]}"
        return 1
    fi
}

# Clean up before building
cleanup_before_build() {
    print_section "Cleaning Up Previous Builds"
    
    # Remove old AppDir
    if [ -d "$SCRIPT_DIR/AppDir" ]; then
        print_info "Removing old AppDir..."
        rm -rf "$SCRIPT_DIR/AppDir"
        print_success "Old AppDir removed"
    fi
    
    # Remove old build logs (keep only recent ones)
    if [ -d "$BUILD_LOG_DIR" ]; then
        print_info "Cleaning old build logs..."
        # Keep only last 5 logs
        ls -t "$BUILD_LOG_DIR"/*.log 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
        print_success "Old logs cleaned"
    fi
    
    # Clear pip cache
    print_info "Clearing pip cache..."
    if pip cache purge > /dev/null 2>&1; then
        print_success "Pip cache cleared"
    fi
    
    echo ""
}

# Build AppImage x86_64
build_appimage_x86_64() {
    print_section "Building AppImage (x86_64)"
    
    local log_file="$BUILD_LOG_DIR/appimage_x86_64_$BUILD_TIMESTAMP.log"
    
    cleanup_before_build
    
    # Set larger temp directory to avoid space issues
    # Try custom temp dir first, fallback to /tmp
    CUSTOM_TEMP="/home/bendeb/build_temp"
    if mkdir -p "$CUSTOM_TEMP" 2>/dev/null && [ -w "$CUSTOM_TEMP" ]; then
        export TMPDIR="$CUSTOM_TEMP"
    else
        export TMPDIR="/tmp/stemweaver_build"
        mkdir -p "$TMPDIR"
    fi
    
    print_info "This may take 20-30 minutes..."
    print_info "Log: $log_file"
    print_info "Using temp dir: $TMPDIR"
    
    # Change to packaging directory and run build directly
    if cd "$SCRIPT_DIR/packaging" && export TMPDIR="$TMPDIR" && bash build_appimage.sh > "$log_file" 2>&1; then
        print_success "AppImage (x86_64) built successfully!"
        if [ -f "$SCRIPT_DIR/StemWeaver-v1.1-x86_64.AppImage" ]; then
            local size=$(ls -lh "$SCRIPT_DIR/StemWeaver-v1.1-x86_64.AppImage" | awk '{print $5}')
            print_info "File: StemWeaver-v1.1-x86_64.AppImage (Size: $size)"
            chmod +x "$SCRIPT_DIR/StemWeaver-v1.1-x86_64.AppImage"
        fi
        return 0
    else
        print_error "AppImage (x86_64) build failed!"
        print_info "Check log: $log_file"
        return 1
    fi
}

# Build AppImage ARM64 (cross-compile or if available)
build_appimage_arm64() {
    print_section "Building AppImage (ARM64)"
    
    local log_file="$BUILD_LOG_DIR/appimage_arm64_$BUILD_TIMESTAMP.log"
    
    cleanup_before_build
    
    # Check if we're on ARM64
    if [ "$(uname -m)" != "aarch64" ]; then
        print_warning "Not running on ARM64 - cross-compilation requires additional setup"
        print_info "Skipping ARM64 build on this system"
        return 1
    fi
    
    print_info "This may take 20-30 minutes..."
    print_info "Log: $log_file"
    
    if cd "$SCRIPT_DIR/packaging" && bash build_appimage.sh > "$log_file" 2>&1; then
        print_success "AppImage (ARM64) built successfully!"
        if [ -f "$SCRIPT_DIR/StemWeaver-v1.1-aarch64.AppImage" ]; then
            local size=$(ls -lh "$SCRIPT_DIR/StemWeaver-v1.1-aarch64.AppImage" | awk '{print $5}')
            print_info "File: StemWeaver-v1.1-aarch64.AppImage (Size: $size)"
            chmod +x "$SCRIPT_DIR/StemWeaver-v1.1-aarch64.AppImage"
        fi
        return 0
    else
        print_error "AppImage (ARM64) build failed!"
        print_info "Check log: $log_file"
        return 1
    fi
}

# Build Arch Linux Package
build_arch_package() {
    print_section "Building Arch Linux Package (PKGBUILD)"
    
    local log_file="$BUILD_LOG_DIR/arch_package_$BUILD_TIMESTAMP.log"
    
    cleanup_before_build
    
    if ! command_exists makepkg; then
        print_error "makepkg not found - this build type requires Arch Linux/Manjaro"
        return 1
    fi
    
    print_info "This may take 15-25 minutes..."
    print_info "Log: $log_file"
    
    if cd "$SCRIPT_DIR/packaging" && makepkg --syncdeps --rmdeps --clean > "$log_file" 2>&1; then
        print_success "Arch package built successfully!"
        local pkg_file=$(ls -t "$SCRIPT_DIR/packaging"/*.pkg.tar.zst 2>/dev/null | head -1)
        if [ -n "$pkg_file" ]; then
            print_info "File: $(basename "$pkg_file")"
            print_info "Install with: sudo pacman -U $pkg_file"
        fi
        return 0
    else
        print_error "Arch package build failed!"
        print_info "Check log: $log_file"
        return 1
    fi
}

# Build Windows executable
build_windows_exe() {
    print_section "Building Windows Executable (.exe)"
    
    local log_file="$BUILD_LOG_DIR/windows_exe_$BUILD_TIMESTAMP.log"
    
    cleanup_before_build
    
    # Set larger temp directory
    CUSTOM_TEMP="/home/bendeb/build_temp"
    if mkdir -p "$CUSTOM_TEMP" 2>/dev/null && [ -w "$CUSTOM_TEMP" ]; then
        export TMPDIR="$CUSTOM_TEMP"
    else
        export TMPDIR="/tmp/stemweaver_build"
        mkdir -p "$TMPDIR"
    fi
    
    if ! command_exists pyinstaller; then
        print_info "Installing PyInstaller..."
        if pip install pyinstaller >> "$log_file" 2>&1; then
            print_success "PyInstaller installed"
        else
            print_error "Failed to install PyInstaller"
            return 1
        fi
    fi
    
    print_info "This may take 15-20 minutes..."
    print_info "Log: $log_file"
    print_info "Using temp dir: $TMPDIR"
    
    # Create PyInstaller spec
    local spec_content="# -*- mode: python ; coding: utf-8 -*-
import sys
from PyInstaller.utils.hooks import get_module_file_attribute

block_cipher = None

a = Analysis(
    ['$SCRIPT_DIR/gui_data/gui_modern_extractor.py'],
    pathex=['$SCRIPT_DIR'],
    binaries=[],
    datas=[
        ('$SCRIPT_DIR/gui_data', 'gui_data'),
        ('$SCRIPT_DIR/gui_data/fonts', 'gui_data/fonts'),
        ('$SCRIPT_DIR/gui_data/img', 'gui_data/img'),
    ],
    hiddenimports=['demucs', 'librosa', 'torch', 'torchaudio', 'soundfile', 'pretty_midi', 'midiutil', 'dearpygui'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludedimports=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='StemWeaver',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='$SCRIPT_DIR/gui_data/img/stemweaver_icon.ico',
)
"
    
    echo "$spec_content" > "$SCRIPT_DIR/StemWeaver.spec"
    
    print_info "Creating Windows executable..."
    if cd "$SCRIPT_DIR" && export TMPDIR="$TMPDIR" && pyinstaller --onefile StemWeaver.spec >> "$log_file" 2>&1; then
        print_success "Windows executable built successfully!"
        
        # Check if exe was created
        if [ -f "$SCRIPT_DIR/dist/StemWeaver.exe" ]; then
            local size=$(ls -lh "$SCRIPT_DIR/dist/StemWeaver.exe" | awk '{print $5}')
            print_info "File: dist/StemWeaver.exe (Size: $size)"
            print_warning "Note: PyInstaller bundle includes Python runtime (~300-500MB)"
        fi
        return 0
    else
        print_error "Windows executable build failed!"
        print_info "Check log: $log_file"
        return 1
    fi
}

# Build from source (development installation)
build_from_source() {
    print_section "Setting up Development Environment"
    
    local log_file="$BUILD_LOG_DIR/source_$BUILD_TIMESTAMP.log"
    
    print_info "Creating Python virtual environment..."
    
    if [ -d "$SCRIPT_DIR/myenv" ]; then
        print_warning "Virtual environment already exists at ./myenv"
        read -p "Use existing environment? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing old environment..."
            rm -rf "$SCRIPT_DIR/myenv"
        fi
    fi
    
    if [ ! -d "$SCRIPT_DIR/myenv" ]; then
        if python3 -m venv "$SCRIPT_DIR/myenv" > "$log_file" 2>&1; then
            print_success "Virtual environment created"
        else
            print_error "Failed to create virtual environment"
            return 1
        fi
    fi
    
    # Activate venv
    source "$SCRIPT_DIR/myenv/bin/activate"
    
    print_info "Upgrading pip, setuptools, wheel..."
    if pip install --upgrade pip setuptools wheel >> "$log_file" 2>&1; then
        print_success "pip upgraded"
    fi
    
    print_info "Installing dependencies from requirements.txt..."
    if pip install -r "$SCRIPT_DIR/requirements.txt" >> "$log_file" 2>&1; then
        print_success "Dependencies installed successfully!"
    else
        print_error "Failed to install dependencies"
        print_info "Check log: $log_file"
        return 1
    fi
    
    print_success "Development environment ready!"
    print_info "Run the app with: source myenv/bin/activate && python gui_data/gui_modern_extractor.py"
    
    return 0
}

# Show build menu
show_menu() {
    echo -e "\n${BLUE}Available Build Options:${NC}\n"
    echo "  1) Build AppImage (x86_64) - Portable Linux executable"
    echo "  2) Build AppImage (ARM64) - For ARM-based Linux systems"
    echo "  3) Build Arch Linux Package - For Arch/Manjaro systems"
    echo "  4) Setup Development Environment - For source development"
    echo "  6) Build Windows Executable (.exe) - For Windows systems"
    echo "  5) Build ALL (x86_64 + Arch Package) - Create both Linux packages"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e "${YELLOW}Enter your choice(s) (e.g., '1 6' for AppImage + Windows, or '5' for all Linux):${NC}"
}

# Parse user choices
parse_choices() {
    local choices=("$@")
    local selected=()
    
    for choice in "${choices[@]}"; do
        case "$choice" in
            1) selected+=("appimage_x86_64") ;;
            2) selected+=("appimage_arm64") ;;
            3) selected+=("arch_package") ;;
            4) selected+=("source") ;;
            6) selected+=("windows_exe") ;;
            5) selected=("appimage_x86_64" "arch_package"); break ;;
            0) print_info "Exiting..."; exit 0 ;;
            *) print_warning "Invalid option: $choice" ;;
        esac
    done
    
    printf '%s\n' "${selected[@]}"
}

# Execute builds
execute_builds() {
    local builds=("$@")
    local successful=()
    local failed=()
    
    print_section "Starting Builds"
    
    for build in "${builds[@]}"; do
        case "$build" in
            appimage_x86_64)
                if build_appimage_x86_64; then
                    successful+=("AppImage x86_64")
                else
                    failed+=("AppImage x86_64")
                fi
                ;;
            appimage_arm64)
                if build_appimage_arm64; then
                    successful+=("AppImage ARM64")
                else
                    failed+=("AppImage ARM64")
                fi
                ;;
            arch_package)
                if build_arch_package; then
                    successful+=("Arch Package")
                else
                    failed+=("Arch Package")
                fi
                ;;
            source)
                if build_from_source; then
                    successful+=("Development Environment")
                else
                    failed+=("Development Environment")
                fi
                ;;
            windows_exe)
                if build_windows_exe; then
                    successful+=("Windows Executable (.exe)")
                else
                    failed+=("Windows Executable (.exe)")
                fi
                ;;
        esac
    done
    
    # Summary
    print_section "Build Summary"
    
    if [ ${#successful[@]} -gt 0 ]; then
        echo -e "${GREEN}Successful builds:${NC}"
        printf '  ✓ %s\n' "${successful[@]}"
    fi
    
    if [ ${#failed[@]} -gt 0 ]; then
        echo -e "${RED}Failed builds:${NC}"
        printf '  ✗ %s\n' "${failed[@]}"
    fi
    
    echo ""
    print_info "Build logs are saved in: $BUILD_LOG_DIR"
}

################################################################################
# Main
################################################################################

main() {
    print_banner
    
    # Check dependencies
    if ! check_dependencies; then
        print_error "Dependency check failed. Exiting."
        exit 1
    fi
    
    # Show menu and get choices
    while true; do
        show_menu
        read -r user_input
        
        # Parse input (space-separated or comma-separated)
        user_input=$(echo "$user_input" | sed 's/,/ /g' | tr -s ' ')
        
        if [ -z "$user_input" ] || [ "$user_input" = " " ]; then
            print_warning "No input provided"
            continue
        fi
        
        # Parse and validate choices (pass as array)
        # Convert space/comma-separated into array
        read -ra choices_array <<< "$(echo "$user_input" | sed 's/,/ /g')"
        selected_builds=$(parse_choices "${choices_array[@]}")
        
        if [ -z "$selected_builds" ]; then
            continue
        fi
        
        # Confirm selections
        echo ""
        print_info "Selected builds:"
        echo "$selected_builds" | while read build; do
            case "$build" in
                appimage_x86_64) echo "  • AppImage (x86_64)" ;;
                appimage_arm64) echo "  • AppImage (ARM64)" ;;
                arch_package) echo "  • Arch Linux Package" ;;
                source) echo "  • Development Environment" ;;
                windows_exe) echo "  • Windows Executable (.exe)" ;;
            esac
        done
        echo ""
        read -p "Proceed with builds? (y/n) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            execute_builds $selected_builds
            
            # Exit after build completes
            print_success "Build process completed!"
            print_info "Check /home/bendeb/stemweaver/ for output files"
            exit 0
        fi
    done
    
    print_success "Done!"
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
