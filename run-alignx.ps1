# AlignX One-Click Runner
# Starts both Backend and Frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         Launching AlignX Stack         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Start Spring Boot Backend in a separate window
Write-Host "`n[1/2] Starting Spring Boot Backend on port 8081..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "mvn clean spring-boot:run" -WorkingDirectory "$PSScriptRoot\alignx_backend"

# Wait for backend to be ready
Write-Host "Waiting for backend on http://localhost:8081/test..." -ForegroundColor Yellow
$retries = 15
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

# 2. Launch Flutter Web Frontend
Write-Host "`n[2/2] Launching Flutter Frontend (Chrome)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "flutter run -d chrome" -WorkingDirectory "$PSScriptRoot\alignx_frontend"

Write-Host "`nBoth services have been triggered! Happy coding with AlignX!" -ForegroundColor Cyan
