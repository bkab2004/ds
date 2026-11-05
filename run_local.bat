@echo off
title DistriFlow Launcher
echo ========================================================
echo        DistriFlow Distributed System Runner
echo ========================================================
echo.
echo Starting all distributed services in separate windows...
echo.

:: 1. Start Coordinator
start "Coordinator (Port 50050)" cmd /k "cd /d %~dp0coordinator && set COORDINATOR_PORT=50050&& set MONGODB_URI=mongodb://localhost:27017&& set DB_NAME=distriflow&& set STORAGE_PATH=%~dp0storage&& python main.py"

:: Wait 2 seconds
timeout /t 2 /nobreak >nul

:: 2. Start Worker 1
start "Worker 1 (Port 50051)" cmd /k "cd /d %~dp0worker && set WORKER_ID=worker-1&& set WORKER_PORT=50051&& set GRPC_HOST=localhost&& set COORDINATOR_HOST=localhost&& set COORDINATOR_PORT=50050&& set MONGODB_URI=mongodb://localhost:27017&& set DB_NAME=distriflow&& set STORAGE_PATH=%~dp0storage&& python main.py"

:: 3. Start Worker 2
start "Worker 2 (Port 50052)" cmd /k "cd /d %~dp0worker && set WORKER_ID=worker-2&& set WORKER_PORT=50052&& set GRPC_HOST=localhost&& set COORDINATOR_HOST=localhost&& set COORDINATOR_PORT=50050&& set MONGODB_URI=mongodb://localhost:27017&& set DB_NAME=distriflow&& set STORAGE_PATH=%~dp0storage&& python main.py"

:: 4. Start Worker 3
start "Worker 3 (Port 50053)" cmd /k "cd /d %~dp0worker && set WORKER_ID=worker-3&& set WORKER_PORT=50053&& set GRPC_HOST=localhost&& set COORDINATOR_HOST=localhost&& set COORDINATOR_PORT=50050&& set MONGODB_URI=mongodb://localhost:27017&& set DB_NAME=distriflow&& set STORAGE_PATH=%~dp0storage&& python main.py"

:: Wait 2 seconds
timeout /t 2 /nobreak >nul

:: 5. Start FastAPI Backend
start "FastAPI Backend (Port 8000)" cmd /k "cd /d %~dp0api && set MONGODB_URI=mongodb://localhost:27017&& set DB_NAME=distriflow&& set STORAGE_PATH=%~dp0storage&& uvicorn main:app --host 0.0.0.0 --port 8000"

:: 6. Start React Frontend
start "React Frontend (Port 5173)" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo ========================================================
echo All services launched!
echo Dashboard:  http://localhost:5173 (or http://localhost:3000)
echo API Docs:   http://localhost:8000/docs
echo.
echo Note: Make sure MongoDB is running on localhost:27017
echo ========================================================
pause
