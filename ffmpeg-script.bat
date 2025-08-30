@echo off
setlocal enabledelayedexpansion

:: Define the base RTMP server address
set "RTMP_SERVER=rtmp://stream.rohitschickencoop.com/live"

:: Define common FFmpeg encoding parameters on a single line
set "FFMPEG_PARAMS=-c:v h264_nvenc -preset fast -s 1280x720 -zerolatency true -threads 1 -g 30 -b:v 800k -maxrate 1000k -bufsize 1600k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5"

:: Define RTSP credentials
set "RTSP_USER=admin"
set "RTSP_PASS=12345"

:: Define monitoring interval (in seconds)
set "MONITOR_INTERVAL=15"

:: Array to store window titles for monitoring
set WINDOW_TITLES=

echo Starting FFmpeg instances with monitoring...
echo.

:: Loop to start 4 FFmpeg instances (0-3, IPs 50-53)
for /l %%i in (0,1,3) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    set "INPUT_URL=rtsp://!RTSP_USER!:!RTSP_PASS!@192.168.1.!IP_LAST_OCTET!:554/ch0_0.264"
    set "CAMERA_NAME=camera_!IP_LAST_OCTET!"
    set "OUTPUT_URL=!RTMP_SERVER!/!CAMERA_NAME!"
    set "WINDOW_TITLE=FFmpeg_Camera_!IP_LAST_OCTET!"

    echo Starting FFmpeg instance for Camera !IP_LAST_OCTET! (!INPUT_URL!)
    start "!WINDOW_TITLE!" cmd /c ffmpeg -i "!INPUT_URL!" %FFMPEG_PARAMS% "!OUTPUT_URL!"
    
    :: Store window title for monitoring
    if "!WINDOW_TITLES!"=="" (
        set "WINDOW_TITLES=!WINDOW_TITLE!"
    ) else (
        set "WINDOW_TITLES=!WINDOW_TITLES! !WINDOW_TITLE!"
    )
    
    :: Small delay between starts
    timeout /t 2 /nobreak >nul
)

echo.
echo All FFmpeg instances have been launched.
echo You should see 4 new command prompt windows.
echo.
echo Starting monitoring loop...
echo Press Ctrl+C to stop monitoring and close all streams.
echo.

:MONITOR_LOOP
echo [%date% %time%] Checking stream status...

:: Check each window and restart if needed
for /l %%i in (0,1,3) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    set "WINDOW_TITLE=FFmpeg_Camera_!IP_LAST_OCTET!"
    
    :: Check if FFmpeg process is running for this camera by looking for the process name and command line
    :: Use wmic to check for ffmpeg processes with the specific camera IP in the command line
    wmic process where "name='ffmpeg.exe' and commandline like '%%192.168.1.!IP_LAST_OCTET!%%'" get processid /format:value 2>nul | find "ProcessId=" >nul
    if errorlevel 1 (
        echo [%date% %time%] WARNING: Camera !IP_LAST_OCTET! stream stopped! Restarting...
        
        :: Kill any lingering cmd windows for this camera first
        for /f "tokens=2" %%p in ('tasklist /fi "windowtitle eq !WINDOW_TITLE!" /fo csv ^| find "cmd.exe"') do (
            taskkill /pid %%p /f >nul 2>&1
        )
        
        :: Recreate the stream parameters
        set "INPUT_URL=rtsp://!RTSP_USER!:!RTSP_PASS!@192.168.1.!IP_LAST_OCTET!:554/ch0_0.264"
        set "CAMERA_NAME=camera_!IP_LAST_OCTET!"
        set "OUTPUT_URL=!RTMP_SERVER!/!CAMERA_NAME!"
        
        :: Wait a moment before restarting
        timeout /t 2 /nobreak >nul
        
        :: Restart the stream
        start "!WINDOW_TITLE!" cmd /c ffmpeg -i "!INPUT_URL!" %FFMPEG_PARAMS% "!OUTPUT_URL!"
        echo [%date% %time%] Camera !IP_LAST_OCTET! stream restarted.
    ) else (
        echo [%date% %time%] Camera !IP_LAST_OCTET! - Running OK
    )
)

echo.
echo Next check in !MONITOR_INTERVAL! seconds...
timeout /t %MONITOR_INTERVAL% /nobreak >nul
goto MONITOR_LOOP

endlocal