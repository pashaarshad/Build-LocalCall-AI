@echo off
title LocalCall AI - Voice Agent Backend
cd /d "%~dp0"
echo ========================================================
echo   LocalCall AI - Voice Agent TTS Backend Service
echo   Port: 8000 | Host: 0.0.0.0
echo ========================================================
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
pause
