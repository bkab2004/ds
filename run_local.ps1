# DistriFlow Local PowerShell Runner
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "       DistriFlow Distributed System Runner" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Start Coordinator
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\coordinator'; `$env:COORDINATOR_PORT='50050'; `$env:MONGODB_URI='mongodb://localhost:27017'; `$env:DB_NAME='distriflow'; `$env:STORAGE_PATH='$baseDir\storage'; python main.py"

Start-Sleep -Seconds 2

# 2. Start Worker 1
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\worker'; `$env:WORKER_ID='worker-1'; `$env:WORKER_PORT='50051'; `$env:GRPC_HOST='localhost'; `$env:COORDINATOR_HOST='localhost'; `$env:COORDINATOR_PORT='50050'; `$env:MONGODB_URI='mongodb://localhost:27017'; `$env:DB_NAME='distriflow'; `$env:STORAGE_PATH='$baseDir\storage'; python main.py"

# 3. Start Worker 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\worker'; `$env:WORKER_ID='worker-2'; `$env:WORKER_PORT='50052'; `$env:GRPC_HOST='localhost'; `$env:COORDINATOR_HOST='localhost'; `$env:COORDINATOR_PORT='50050'; `$env:MONGODB_URI='mongodb://localhost:27017'; `$env:DB_NAME='distriflow'; `$env:STORAGE_PATH='$baseDir\storage'; python main.py"

# 4. Start Worker 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\worker'; `$env:WORKER_ID='worker-3'; `$env:WORKER_PORT='50053'; `$env:GRPC_HOST='localhost'; `$env:COORDINATOR_HOST='localhost'; `$env:COORDINATOR_PORT='50050'; `$env:MONGODB_URI='mongodb://localhost:27017'; `$env:DB_NAME='distriflow'; `$env:STORAGE_PATH='$baseDir\storage'; python main.py"

Start-Sleep -Seconds 2

# 5. Start FastAPI
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\api'; `$env:MONGODB_URI='mongodb://localhost:27017'; `$env:DB_NAME='distriflow'; `$env:STORAGE_PATH='$baseDir\storage'; uvicorn main:app --host 0.0.0.0 --port 8000"

# 6. Start Frontend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\frontend'; npm run dev"

Write-Host "`nAll services started in separate windows!" -ForegroundColor Green
Write-Host "Dashboard:  http://localhost:5173" -ForegroundColor Yellow
Write-Host "API Docs:   http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "`n(Ensure MongoDB is running locally on port 27017)" -ForegroundColor Gray
