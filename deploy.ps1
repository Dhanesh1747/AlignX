# AlignX One-Click Build & Deploy Script
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       AlignX Build & Deploy Runner        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$projectRoot = $PSScriptRoot
$frontendDir = Join-Path $projectRoot "alignx_frontend"
$backendDir  = Join-Path $projectRoot "alignx_backend"
$staticTarget = Join-Path $backendDir "src\main\resources\static"

# Step 1: Build Flutter Web Release
Write-Host "`n[1/4] Building Flutter Web Release..." -ForegroundColor Yellow
Push-Location $frontendDir
try {
    flutter build web --release
} finally {
    Pop-Location
}

# Step 2: Copy Web Release to Spring Boot static resources
Write-Host "`n[2/4] Syncing web assets to Spring Boot static resources..." -ForegroundColor Yellow
if (-not (Test-Path $staticTarget)) {
    New-Item -ItemType Directory -Force -Path $staticTarget | Out-Null
}
Copy-Item -Path "$frontendDir\build\web\*" -Destination $staticTarget -Recurse -Force
Write-Host "Synced assets to $staticTarget" -ForegroundColor Green

# Step 3: Package Spring Boot Executable JAR
Write-Host "`n[3/4] Packaging unified Spring Boot full-stack JAR..." -ForegroundColor Yellow
Push-Location $backendDir
try {
    .\mvnw.cmd clean package -DskipTests
} finally {
    Pop-Location
}

# Step 4: Run Application
Write-Host "`n[4/4] Starting AlignX on http://localhost:8085..." -ForegroundColor Green
$jarPath = Join-Path $backendDir "target\alignx_backend-0.0.1-SNAPSHOT.jar"
Start-Process "java" -ArgumentList "-jar `"$jarPath`""
Start-Sleep -Seconds 3
Start-Process "http://localhost:8085"

Write-Host "`nAlignX deployed and running successfully at http://localhost:8085 !" -ForegroundColor Cyan
