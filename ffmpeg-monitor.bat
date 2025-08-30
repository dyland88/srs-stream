@echo off
setlocal enabledelayedexpansion

:: Enhanced FFmpeg Stream Monitor with Logging
:: This script provides more detailed monitoring and logging capabilities

:: Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

:: Define log file with timestamp
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set DATE_LOG=%%c-%%a-%%b
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIME_LOG=%%a-%%b
set "LOG_FILE=logs\ffmpeg-monitor_%DATE_LOG%_%TIME_LOG%.log"

:: Configuration
set "RTMP_SERVER=rtmp://stream.rohitschickencoop.com/live"
set "FFMPEG_PARAMS=-c:v h264_nvenc -preset fast -s 1280x720 -zerolatency true -threads 1 -g 30 -b:v 800k -maxrate 1000k -bufsize 1600k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5"
set "RTSP_USER=admin"
set "RTSP_PASS=12345"
set "MONITOR_INTERVAL=30"
set "RESTART_DELAY=5"
set "MAX_RESTART_ATTEMPTS=3"

:: Initialize restart counters
for /l %%i in (0,1,3) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    set "RESTART_COUNT_!IP_LAST_OCTET!=0"
)

echo ================================= >> "%LOG_FILE%"
echo FFmpeg Monitor Started: %date% %time% >> "%LOG_FILE%"
echo ================================= >> "%LOG_FILE%"
echo.

call :LOG "Starting FFmpeg Stream Monitor with Enhanced Logging"
call :LOG "Log file: %LOG_FILE%"
call :LOG "Monitor interval: %MONITOR_INTERVAL% seconds"
echo.

:: Start initial streams
call :LOG "Starting initial FFmpeg instances..."
for /l %%i in (0,1,3) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    call :START_STREAM !IP_LAST_OCTET!
    timeout /t 2 /nobreak >nul
)

call :LOG "All initial FFmpeg instances launched"
call :LOG "Starting monitoring loop... Press Ctrl+C to stop"
echo.

:MONITOR_LOOP
call :LOG "=== Health Check ==="

for /l %%i in (0,1,3) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    call :CHECK_AND_RESTART !IP_LAST_OCTET!
)

call :LOG "Next check in %MONITOR_INTERVAL% seconds..."
echo.
timeout /t %MONITOR_INTERVAL% /nobreak >nul
goto MONITOR_LOOP

:: Function to start a stream
:START_STREAM
set "IP=%1"
set "INPUT_URL=rtsp://!RTSP_USER!:!RTSP_PASS!@192.168.1.%IP%:554/ch0_0.264"
set "CAMERA_NAME=camera_%IP%"
set "OUTPUT_URL=!RTMP_SERVER!/!CAMERA_NAME!"
set "WINDOW_TITLE=FFmpeg_Camera_%IP%"

call :LOG "Starting stream for Camera %IP% (192.168.1.%IP%)"
start "!WINDOW_TITLE!" cmd /c ffmpeg -i "!INPUT_URL!" %FFMPEG_PARAMS% "!OUTPUT_URL!"
goto :eof

:: Function to check and restart a stream if needed
:CHECK_AND_RESTART
set "IP=%1"
set "WINDOW_TITLE=FFmpeg_Camera_%IP%"

:: Check if FFmpeg process is running for this camera by looking for the actual ffmpeg.exe process
:: Use wmic to check for ffmpeg processes with the specific camera IP in the command line
wmic process where "name='ffmpeg.exe' and commandline like '%%192.168.1.%IP%%%'" get processid /format:value 2>nul | find "ProcessId=" >nul
if errorlevel 1 (
    :: Stream is down
    set /a "CURRENT_RESTARTS=!RESTART_COUNT_%IP%!"
    if !CURRENT_RESTARTS! LSS %MAX_RESTART_ATTEMPTS% (
        set /a "RESTART_COUNT_%IP%=!CURRENT_RESTARTS! + 1"
        call :LOG "WARNING: Camera %IP% stream stopped! Attempt !RESTART_COUNT_%IP%! of %MAX_RESTART_ATTEMPTS%"
        
        :: Kill any lingering cmd windows for this camera first
        for /f "skip=1 tokens=2 delims=," %%p in ('tasklist /fi "windowtitle eq !WINDOW_TITLE!" /fo csv 2^>nul') do (
            if not "%%p"=="PID" (
                call :LOG "Cleaning up lingering process %%p for Camera %IP%"
                taskkill /pid %%p /f >nul 2>&1
            )
        )
        
        call :LOG "Waiting %RESTART_DELAY% seconds before restart..."
        timeout /t %RESTART_DELAY% /nobreak >nul
        call :START_STREAM %IP%
        call :LOG "Camera %IP% stream restarted (Attempt !RESTART_COUNT_%IP%!)"
    ) else (
        call :LOG "ERROR: Camera %IP% has failed %MAX_RESTART_ATTEMPTS% times. Manual intervention required!"
        call :LOG "Skipping automatic restart for Camera %IP%"
    )
) else (
    :: Stream is running - reset restart counter
    set "RESTART_COUNT_%IP%=0"
    call :LOG "Camera %IP% - Running OK"
)
goto :eof

:: Function to log messages with timestamp
:LOG
set "MSG=%~1"
echo [%date% %time%] %MSG%
echo [%date% %time%] %MSG% >> "%LOG_FILE%"
goto :eof

endlocal
