@echo off
setlocal enabledelayedexpansion

:: Define the base RTMP server address
set "RTMP_SERVER=rtmp://stream.rohitschickencoop.com/live"

:: Define common FFmpeg encoding parameters on a single line
set "FFMPEG_PARAMS=-c:v libx264 -preset veryfast -tune zerolatency -g 60 -b:v 1000k -maxrate 1200k -bufsize 2000k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv"

:: Define RTSP credentials
set "RTSP_USER=admin"
set "RTSP_PASS=12345"

:: Loop to start 8 FFmpeg instances
for /l %%i in (0,1,7) do (
    set /a "IP_LAST_OCTET=50 + %%i"
    set "INPUT_URL=rtsp://!RTSP_USER!:!RTSP_PASS!@192.168.1.!IP_LAST_OCTET!:554/ch0_0.264"
    set "CAMERA_NAME=camera_!IP_LAST_OCTET!"
    set "OUTPUT_URL=!RTMP_SERVER!/!CAMERA_NAME!"

    echo Starting FFmpeg instance for !INPUT_URL! to !OUTPUT_URL!
    start "FFmpeg Instance !IP_LAST_OCTET!" cmd /k ffmpeg -i "!INPUT_URL!" %FFMPEG_PARAMS% "!OUTPUT_URL!"
)

echo All 8 FFmpeg instances have been launched.
echo You should see 8 new command prompt windows.
echo "Close the command prompt windows to stop the FFmpeg streams."

endlocal
pause