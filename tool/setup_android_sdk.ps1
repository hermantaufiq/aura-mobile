# AURA - Android SDK Setup Script (PowerShell)
# =============================================
# Jalankan sebagai Administrator:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\tool\setup_android_sdk.ps1
#
# Script ini akan:
#   1. Download Android Command Line Tools
#   2. Install SDK Platform 35 + Build Tools
#   3. Konfigurasi ANDROID_HOME environment variable

$androidHome = "C:\Android"
$sdkDir = "$androidHome\cmdline-tools\latest"
$toolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$toolsZip = "$env:TEMP\cmdline-tools.zip"

Write-Host ""
Write-Host "  AURA Android SDK Setup" -ForegroundColor Cyan
Write-Host "  ========================" -ForegroundColor Cyan
Write-Host ""

# Step 1 - Buat direktori
Write-Host "[1/5] Membuat direktori Android SDK..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $sdkDir | Out-Null
Write-Host "      OK: $androidHome" -ForegroundColor Green

# Step 2 - Download Command Line Tools
Write-Host "[2/5] Download Android Command Line Tools (~100MB)..." -ForegroundColor Yellow
if (!(Test-Path "$sdkDir\bin\sdkmanager.bat")) {
    try {
        Invoke-WebRequest -Uri $toolsUrl -OutFile $toolsZip -UseBasicParsing
        Write-Host "      OK: Download selesai" -ForegroundColor Green
    } catch {
        Write-Host "      ERROR: Gagal download. Periksa koneksi internet." -ForegroundColor Red
        exit 1
    }

    # Extract
    Write-Host "      Extracting..." -ForegroundColor Gray
    $tempExtract = "$env:TEMP\cmdline-tools-extract"
    Expand-Archive -Path $toolsZip -DestinationPath $tempExtract -Force
    # Move ke lokasi yang benar
    $extractedDir = "$tempExtract\cmdline-tools"
    if (Test-Path $extractedDir) {
        Copy-Item -Path "$extractedDir\*" -Destination $sdkDir -Recurse -Force
    }
    Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $toolsZip -Force -ErrorAction SilentlyContinue
    Write-Host "      OK: Extracted ke $sdkDir" -ForegroundColor Green
} else {
    Write-Host "      SKIP: Command line tools sudah ada" -ForegroundColor Gray
}

# Step 3 - Set Environment Variables
Write-Host "[3/5] Mengatur environment variables..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidHome, "User")

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
    "$androidHome\cmdline-tools\latest\bin",
    "$androidHome\platform-tools",
    "$androidHome\emulator"
)
foreach ($p in $pathsToAdd) {
    if ($currentPath -notlike "*$p*") {
        $currentPath = "$p;$currentPath"
    }
}
[System.Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
$env:ANDROID_HOME = $androidHome
$env:Path = "$androidHome\cmdline-tools\latest\bin;$androidHome\platform-tools;$env:Path"
Write-Host "      OK: ANDROID_HOME = $androidHome" -ForegroundColor Green

# Step 4 - Install SDK Packages
Write-Host "[4/5] Install Android SDK packages..." -ForegroundColor Yellow
Write-Host "      (Ini akan memakan waktu beberapa menit)" -ForegroundColor Gray
$sdkmanager = "$sdkDir\bin\sdkmanager.bat"
if (Test-Path $sdkmanager) {
    # Accept licenses
    Write-Host "      Accepting licenses..." -ForegroundColor Gray
    "y`ny`ny`ny`ny`ny`n" | & $sdkmanager --licenses 2>&1 | Out-Null

    # Install packages
    $packages = @(
        "platform-tools",
        "platforms;android-35",
        "build-tools;35.0.0",
        "system-images;android-35;google_apis;x86_64"
    )
    foreach ($pkg in $packages) {
        Write-Host "      Installing: $pkg" -ForegroundColor Gray
        & $sdkmanager $pkg 2>&1 | Out-Null
        Write-Host "      OK: $pkg" -ForegroundColor Green
    }
} else {
    Write-Host "      ERROR: sdkmanager tidak ditemukan di $sdkmanager" -ForegroundColor Red
    exit 1
}

# Step 5 - Create Android Virtual Device (Emulator)
Write-Host "[5/5] Membuat Android Emulator (Pixel 7 API 35)..." -ForegroundColor Yellow
$avdmanager = "$sdkDir\bin\avdmanager.bat"
if (Test-Path $avdmanager) {
    "no" | & $avdmanager create avd `
        --name "AURA_Pixel7" `
        --package "system-images;android-35;google_apis;x86_64" `
        --device "pixel_7" `
        --force 2>&1 | Out-Null
    Write-Host "      OK: Emulator 'AURA_Pixel7' dibuat" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Setup selesai!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Langkah selanjutnya:" -ForegroundColor White
Write-Host "  1. TUTUP dan BUKA KEMBALI terminal (reload PATH)" -ForegroundColor Yellow
Write-Host "  2. Jalankan emulator:" -ForegroundColor Yellow
Write-Host "     emulator -avd AURA_Pixel7" -ForegroundColor Cyan
Write-Host "  3. Jalankan aplikasi:" -ForegroundColor Yellow
Write-Host "     flutter run" -ForegroundColor Cyan
Write-Host "  4. Atau build APK:" -ForegroundColor Yellow
Write-Host "     flutter build apk --release" -ForegroundColor Cyan
Write-Host ""
