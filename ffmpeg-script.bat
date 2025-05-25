@echo off
setlocal enabledelayedexpansion

:: Define the base RTMP server address
set "RTMP_SERVER=rtmp://35.172.84.215:1935/live/"

:: Define common FFmpeg encoding parameters on a single line to avoid quoting issues with line continuation
set "FFMPEG_PARAMS=-re -f lavfi -i "testsrc=size=640x480:rate=30:duration=99999999" -c:v libx264 -preset veryfast -tune zerolatency -g 60 -bf 0 -b:v 800k -maxrate 900k -bufsize 1800k -f flv"

:: Loop to start 8 FFmpeg instances
for /l %%i in (1,1,8) do (
    set "CAMERA_NAME=camera_%%i"
    set "OUTPUT_URL=!RTMP_SERVER!!CAMERA_NAME!"

    :: Use 'start "FFmpeg Instance %%i" cmd /k' to open a new command prompt window
    :: '/k' keeps the window open after the command finishes, so you can see output
    :: '/c' would close the window immediately after the command finishes
    echo Starting FFmpeg instance %%i for !OUTPUT_URL!
    start "FFmpeg Instance %%i" cmd /k ffmpeg %FFMPEG_PARAMS% "!OUTPUT_URL!"
)

echo All 8 FFmpeg instances have been launched.
echo You should see 8 new command prompt windows.
echo "Close the command prompt windows to stop the FFmpeg streams."

endlocal
pause
