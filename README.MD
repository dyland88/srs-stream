# SRS Stream Setup

- I have a docker compose file but it's not needed for these instructions
- The player.html is for quick testing

## AWS Lightsail Setup

- Set static IP.
- Opened all ports (probably not the most secure but idgaf)
  - Or just open ports 1935 (for rtmp), 8080, 80 (for HTTP challenge) and 443 (for HTTPS)

### Add subdomain for HTTPS streaming

- Go to vercel "domains" page on dashboard and add a stream DNS record of type "A" with an IP that points to the lightsail static IP.
- Install Docker:
  ```bash
  sudo apt-get install docker.io
  ```
- Pull SRS Docker image:
  ```bash
  sudo docker pull ossrs/srs:v6.0.166
  ```
- Install docker-compose:
  ```bash
    sudo apt-get install -y docker-compose
  ```
- Copy SRS configuration, docker compose, and caddyfile (from Windows machine):
  - You will need to use your key to scp to the aws instance
  ```bash
  scp -i SrsKey.pem srs.conf docker-compose.yaml Caddyfile ubuntu@35.172.84.215:~
  ```
- Run SRS Docker container:

  ```bash
  sudo docker-compose up -d
  ```

- Old command to run SRS without Caddy HTTPS authentication
  ```bash
  sudo docker run --rm -it -p 1935:1935 -p 8080:8080 -v ~/srs.conf:/usr/local/srs/conf/srs.conf ossrs/srs:v6.0.166 ./objs/srs -c /usr/local/srs/conf/srs.conf
  ```

## Streaming from OBS

- Set OBS stream server to: `rtmp://stream.YOURDOMAIN.com/live`
- Set stream key to: `camera_1`
- View stream using: `https://stream.YOURDOMAIN.com/live/camera_1.m3u8` and player.html

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

### Viewing the video

- You can view the video by embedding `https://stream.YOURDOMAIN.com/live/camera_1.m3u8` in a web video player
