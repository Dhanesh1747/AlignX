# AlignX One-Click Runner
# Starts both Backend and Frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         Launching AlignX Stack         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Start MySQL
Write-Host "`n[1/3] Checking MySQL on localhost:3306..." -ForegroundColor Green
$mysqlReady = Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -InformationLevel Quiet
if (-not $mysqlReady) {
    Write-Host "No local MySQL listener found; starting the bundled MySQL container..." -ForegroundColor Yellow
    docker compose up -d --wait mysql
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not start MySQL. Start your local MySQL service or install Docker Desktop, then retry." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Using the MySQL service already running on localhost:3306." -ForegroundColor Green
}

# 2. Start Spring Boot Backend in a separate window
Write-Host "`n[2/3] Starting Spring Boot Backend on port 8081..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "mvn spring-boot:run" -WorkingDirectory "$PSScriptRoot\alignx_backend"

# Wait for backend to be ready
Write-Host "Waiting for backend on http://localhost:8081/test..." -ForegroundColor Yellow
$retries = 30
$ready = $false
while ($retries -gt 0 -and -not $ready) {
    Start-Sleep -Seconds 2
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:8081/test" -TimeoutSec 2 -ErrorAction Stop
        if ($res -like "*Backend is live*") {
            $ready = $true
        }
    } catch {
        Write-Host "." -NoNewline
    }
    $retries--
}

if ($ready) {
    Write-Host "`n✅ Backend is UP and running at http://localhost:8081!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Backend is still initializing, proceeding with frontend launch..." -ForegroundColor Yellow
}

# 3. Launch Flutter Web Frontend
Write-Host "`n[3/3] Launching Flutter Frontend (Chrome)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", 'flutter pub get; if ($LASTEXITCODE -eq 0 -or (Test-Path ".dart_tool/package_config.json")) { flutter run -d chrome --no-pub }' -WorkingDirectory "$PSScriptRoot\alignx_frontend"

Write-Host "`nBoth services have been triggered! Happy coding with AlignX!" -ForegroundColor Cyan
