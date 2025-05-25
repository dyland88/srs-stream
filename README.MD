On aws lightsail

- set static ip
- opened ports
- sudo apt-get install docker.io
- sudo docker pull ossrs/srs:v6.0.166
- sudo docker run --rm -it -p 1935:1935 -p 1985:1985 -p 8080:8080 ossrs/srs:5
  To stream from OBS
- set obs stream to rtmp://AMAZON_INSTANCE_IP/live
- set stream key to "livestream"
- view stream at rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/livestream
  To encode video camera stream
- ffmpeg -rtsp_transport tcp -i "rtsp://user:pass@192.168.1.101/path" -c:v copy -c:a aac -f flv rtmp://YOUR_LIGHTSAIL_PUBLIC_IP:1935/live/camera1
