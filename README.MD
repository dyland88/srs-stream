# SRS Stream Setup

- I have a docker compose file but it's not needed for these instructions
- The player.html is for quick testing

## AWS Lightsail Setup

- Set static IP.
- Opened all ports (probably not the most secure but idgaf)
  - Or just open ports 1935 and 8080
- Install Docker:
  ```bash
  sudo apt-get install docker.io
  ```
- Pull SRS Docker image:
  ```bash
  sudo docker pull ossrs/srs:v6.0.166
  ```
- Copy SRS configuration (from Windows machine):
  - You will need to use your key to ssh into the aws instance
  ```bash
  scp -i ./path/to/key.pem srs.conf ubuntu@35.172.84.215:~
  ```
- Run SRS Docker container:
  ```bash
  sudo docker run --rm -it -p 1935:1935 -p 8080:8080 ossrs/srs:5 ./objs/srs -c conf/hls.conf
  ```

## Streaming from OBS

- Set OBS stream server to: `rtmp://YOUR_LIGHTSAIL_PUBLIC_IP/live`
- Set stream key to: `camera_1`
- View stream using: `rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/camera_1` and player.html

## Streaming from FFmpeg

### To transcode from IP webcam

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://USERNAME:PASSWORD@YOUR_WEBCAM_IP_X:PORT/PATH" \
  -c:v libx264 -preset veryfast -tune zerolatency -b:v 1000k -maxrate 1200k -bufsize 2000k \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -f flv rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/camera_1
```

### To transmit a test video

```bash
ffmpeg -re -f lavfi -i "testsrc=size=640x480:rate=30:duration=99999999" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 60 -bf 0 -b:v 800k -maxrate 900k -bufsize 1800k \
  -f flv rtmp://35.172.84.215:1935/live/camera_1
```

### Automatically Run Multiple FFmpeg Instances

- Execute the script:
  ```bash
  ./ffmpeg-script.bat
  ```
