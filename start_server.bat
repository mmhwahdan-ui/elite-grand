@echo off
title Elite Grand Server & Tunnel
cd /d "d:\elite grand"
set "PATH=C:\Program Files\nodejs;%PATH%"

:: Kill any old lingering instances on port 8080 or cloudflared
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM cloudflared.exe >nul 2>&1

:: Start Node server in background
start "" /b node server.js

:: Wait 2 seconds
timeout /t 2 /nobreak >nul

:: Start Cloudflare tunnel
start "" "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:8080
