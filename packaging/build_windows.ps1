# StemWeaver Windows Build Script
# Run this in PowerShell as Administrator

$ErrorActionPreference = "Stop"

Write-Host "=== StemWeaver Windows Build ===" -ForegroundColor Green

# Check if Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Please install Python 3.10+ from python.org" -ForegroundColor Red
    exit 1
}

# Check if NSIS is installed (for installer)
$nsisPath = "C:\Program Files (x86)\NSIS\makensis.exe"
$hasNSIS = Test-Path $nsisPath

# Create build directory
$buildDir = ".\build\windows"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Create virtual environment
Write-Host "Creating virtual environment..." -ForegroundColor Yellow
python -m venv "$buildDir\venv"
& "$buildDir\venv\Scripts\activate.ps1"

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt

# Create application directory structure
Write-Host "Creating application structure..." -ForegroundColor Yellow
$appDir = "$buildDir\StemWeaver"
New-Item -ItemType Directory -Force -Path "$appDir\gui_data" | Out-Null
New-Item -ItemType Directory -Force -Path "$appDir\lib_v5" | Out-Null
New-Item -ItemType Directory -Force -Path "$appDir\models" | Out-Null
New-Item -ItemType Directory -Force -Path "$appDir\venv" | Out-Null

# Copy application files
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item -Path ".\gui_data\*" -Destination "$appDir\gui_data\" -Recurse -Force
Copy-Item -Path ".\lib_v5\*" -Destination "$appDir\lib_v5\" -Recurse -Force
Copy-Item -Path ".\models\*" -Destination "$appDir\models\" -Recurse -Force
Copy-Item -Path ".\requirements.txt" -Destination "$appDir\"
Copy-Item -Path ".\README.md" -Destination "$appDir\"
Copy-Item -Path ".\LICENSE" -Destination "$appDir\"

# Copy venv (site-packages only)
Write-Host "Copying Python environment..." -ForegroundColor Yellow
$sitePackages = "$buildDir\venv\Lib\site-packages"
Copy-Item -Path "$sitePackages\*" -Destination "$appDir\venv\" -Recurse -Force

# Create launcher script
Write-Host "Creating launcher..." -ForegroundColor Yellow
$launcher = @'
@echo off
cd /d "%~dp0"
set PYTHONPATH=%CD%;%CD%\lib_v5;%CD%\gui_data
if exist "venv\Scripts\python.exe" (
    "venv\Scripts\python.exe" "gui_data\gui_modern_extractor.py" %*
) else (
    python "gui_data\gui_modern_extractor.py" %*
)
'@
$launcher | Out-File -FilePath "$appDir\StemWeaver.bat" -Encoding ASCII

# Create Start Menu shortcut script
$shortcutScript = @'
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\StemWeaver.lnk")
$Shortcut.TargetPath = "$PSScriptRoot\StemWeaver.bat"
$Shortcut.WorkingDirectory = "$PSScriptRoot"
$Shortcut.IconLocation = "$PSScriptRoot\gui_data\img\GUI-Icon.ico"
$Shortcut.Save()
'@
$shortcutScript | Out-File -FilePath "$appDir\CreateShortcut.ps1" -Encoding UTF8

# Create uninstaller script
$uninstaller = @'
# StemWeaver Uninstaller
Write-Host "Uninstalling StemWeaver..." -ForegroundColor Red

# Remove Start Menu shortcut
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\StemWeaver.lnk"
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath }

# Remove registry entries (if any)
Remove-Item -Path "HKCU:\Software\StemWeaver" -Recurse -ErrorAction SilentlyContinue

Write-Host "StemWeaver has been uninstalled." -ForegroundColor Green
Write-Host "User data is preserved in:"
Write-Host "  %APPDATA%\StemWeaver"
Write-Host "  %USERPROFILE%\StemWeaver_Output"
'@
$uninstaller | Out-File -FilePath "$appDir\Uninstall.ps1" -Encoding UTF8

# Create ZIP package
Write-Host "Creating ZIP package..." -ForegroundColor Yellow
$zipPath = "$buildDir\StemWeaver-Windows-x64.zip"
Compress-Archive -Path "$appDir\*" -DestinationPath $zipPath -Force

# Create NSIS installer (if NSIS is installed)
if ($hasNSIS) {
    Write-Host "Creating NSIS installer..." -ForegroundColor Yellow
    
    $nsisScript = @'
!include "MUI2.nsh"

Name "StemWeaver v1.1"
OutFile "StemWeaver-Setup.exe"
InstallDir "$PROGRAMFILES64\StemWeaver"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath $INSTDIR
    File /r "StemWeaver\*"
    
    # Create Start Menu shortcut
    CreateShortcut "$SMPROGRAMS\StemWeaver.lnk" "$INSTDIR\StemWeaver.bat" "" "$INSTDIR\gui_data\img\GUI-Icon.ico"
    
    # Create Desktop shortcut
    CreateShortcut "$DESKTOP\StemWeaver.lnk" "$INSTDIR\StemWeaver.bat" "" "$INSTDIR\gui_data\img\GUI-Icon.ico"
    
    # Registry for uninstaller
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StemWeaver" "DisplayName" "StemWeaver"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StemWeaver" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StemWeaver" "DisplayIcon" "$INSTDIR\gui_data\img\GUI-Icon.ico"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StemWeaver" "Publisher" "bendeb creations"
    
    # Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$SMPROGRAMS\StemWeaver.lnk"
    Delete "$DESKTOP\StemWeaver.lnk"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\StemWeaver"
    RMDir /r "$INSTDIR"
SectionEnd
'@
    
    $nsisScript | Out-File -FilePath "$buildDir\StemWeaver.nsi" -Encoding ASCII
    
    # Copy files to temp directory for NSIS
    $tempDir = "$buildDir\nsis_temp"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    Copy-Item -Path "$appDir\*" -Destination $tempDir -Recurse -Force
    Copy-Item -Path ".\LICENSE" -Destination $tempDir
    
    # Run NSIS
    Push-Location $buildDir
    & $nsisPath "StemWeaver.nsi"
    Pop-Location
    
    # Move installer to build directory
    if (Test-Path "$buildDir\StemWeaver-Setup.exe") {
        Move-Item -Path "$buildDir\StemWeaver-Setup.exe" -Destination "$buildDir\StemWeaver-Windows-x64-Setup.exe" -Force
    }
    
    # Cleanup
    Remove-Item -Path $tempDir -Recurse -Force
    Remove-Item -Path "$buildDir\StemWeaver.nsi" -Force
}

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "ZIP Package: $zipPath"
if ($hasNSIS) {
    Write-Host "Installer: $buildDir\StemWeaver-Windows-x64-Setup.exe"
}
Write-Host ""
Write-Host "To run: .\StemWeaver\StemWeaver.bat"