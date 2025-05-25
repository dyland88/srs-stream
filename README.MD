# On aws lightsail

- set static ip
- opened ports
- sudo apt-get install docker.io
- sudo docker pull ossrs/srs:v6.0.166
- sudo docker run --rm -it -p 1935:1935 -p 1985:1985 -p 8080:8080 ossrs/srs:5

### To stream from OBS

- set obs stream to rtmp://AMAZON_INSTANCE_IP/live
- set stream key to "livestream"
- view stream at rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/livestream

# To encode video camera stream

- ffmpeg -rtsp_transport tcp -i "rtsp://USERNAME:PASSWORD@YOUR_WEBCAM_IP_X:PORT/PATH" \
  -c:v libx264 -preset veryfast -tune zerolatency -b:v 1000k -maxrate 1200k -bufsize 2000k \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -f flv rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/camera_X_stream

- ffmpeg -re -f lavfi -i "testsrc=size=640x480:rate=30:duration=99999999" -c:v libx264 -preset veryfast -tune zerolatency -g 60 -bf 0 -b:v 800k -maxrate 900k -bufsize 1800k -f flv rtmp://35.172.84.215:1935/live/camera_test1

# To make srs playback work:

### on local machine:

- scp -i ./SrsKey.pem srs.conf ubuntu@35.172.84.215:~

### on lightsail:

- sudo docker run --rm -it -p 1935:1935 -p 8080:8080 ossrs/srs:5 ./objs/srs -c conf/hls.conf
