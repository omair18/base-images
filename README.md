# base-images
Useful Docker files for baseimages.
OpenVino Inferencing engine and tracking plugins to be included, also included Intel hardware accelaration software stack such as media driver, media SDK, OpenVINO, gmmlib and libva.
Also conctains OpenCV 4.2.0-openvino compiled with Gstreamer and python3.


# Useful Gstreamer command

open rtsp stream
``` sh
gst-launch-1.0 rtspsrc location=rtsp://admin:admin123@192.168.0.100:554/Streaming/Channels/101 latency=10 ! decodebin ! autovideosink

gst-launch-1.0 rtspsrc location=rtsp://streamserve.ok.ubc.ca:1935/timcam/timcam.stream latency=10 ! decodebin ! autovideosink

gst-launch-1.0 rtspsrc location=rtsp://192.168.0.102:8554/ latency=100 ! queue ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! videoscale ! video/x-raw,width=640,height=480 ! autovideosink


GST_DEBUG=fpsdisplaysink:5 /opt/gstreamer-dist-master/bin/gst-launch-1.0 --gst-plugin-path=/opt/gstreamer-dist-master/lib filesrc location=packages_short.mp4 ! decodebin ! videoconvert ! fpsdisplaysink sync=false
```
public rtsp streams available
```
rtsp://streamer1.streamhost.org:1935/salive/GMIalfah
https://github.com/warren-bank/Android-RTSP-IPCam-Viewer/blob/master/.etc/sample_file_import_data/video_streams.json
```
open udp stream
```sh 
gst-launch-1.0 udpsrc port=5000 ! application/x-rtp,media=video,payload=96,clock-rate=90000,encoding-name=H264  ! rtpjitterbuffer ! rtph264depay ! h264parse ! decodebin ! videoconvert  !  video/x-raw, format=I420 ! fpsdisplaysink sync=false async=false max-buffers=60 drop=true
```

open mp4 file with vaapi for hardware acceleration
```sh
gst-launch-1.0 -v filesrc location=/path/to/video.mp4 ! qtdemux ! vaapidecodebin ! vaapisink fullscreen=true
```
sample commands using vaapi plugin
* Play an H.264 video with an MP4 container in fullscreen mode
    ```sh 
    gst-launch-1.0 -v filesrc location=/path/to/video.mp4 ! \
    qtdemux ! vaapidecodebin ! vaapisink fullscreen=true
    ```

* Play a raw MPEG-2 interlaced stream
    ``` sh
    gst-launch-1.0 -v filesrc location=/path/to/mpeg2.bits ! \
    mpegvideoparse ! vaapimpeg2dec ! vaapipostproc ! vaapisink
    ```

* Convert from one pixel format to another, while also downscaling
    ```sh 
    gst-launch-1.0 -v filesrc location=/path/to/raw_video.yuv ! \
    videoparse format=yuy2 width=1280 height=720 ! \
    vaapipostproc format=nv12 height=480 ! vaapisink
    ```

* Encode a 1080p stream in raw I420 format into H.264
    ```sh
    gst-launch-1.0 -v filesrc location=/path/to/raw_video.yuv ! \
    videoparse format=i420 width=1920 height=1080 framerate=30/1 ! \
    vaapih264enc rate-control=cbr tune=high-compression ! \
    qtmux ! filesink location=/path/to/encoded_video.mp4
    ```

Convert motec camera mjpg to h264 and stream it to localhost
```sh
gst-launch-1.0 -v rtspsrc location=rtsp://10.0.0.11:8554/MCDE3000 latency=0 ! decodebin ! x264enc tune=zerolatency bitrate=500 speed-preset=superfast ! h264parse ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=5000
```
Playback h264 from locahost
```sh
gst-launch-1.0 -v udpsrc port=5000 ! application/x-rtp,clock-rate=90000,payload=96 ! rtph264depay ! decodebin ! videoconvert ! autovideosink
```

Pipe udp h264 to [jsmpeg](https://github.com/phoboslab/jsmpeg)
```sh
GST_DEBUG=3 gst-launch-1.0 -v udpsrc port=5000 ! application/x-rtp,clock-rate=90000,payload=96 ! rtph264depay ! decodebin ! videoconvert ! videorate max-rate=25 ! avenc_mpeg1video dct_algo=1 gop-size=30 max-bframes=0 ! mpegtsmux ! curlhttpsink location=http://127.0.0.1:8081/yoursecret
```

intel vaapi h264 decode
```sh
GST_DEBUG=3 gst-launch-1.0 -v udpsrc port=5000 ! application/x-rtp,clock-rate=90000,payload=96 ! rtph264depay ! vaapih264dec low-latency=true ! videorate ! video/x-raw,framerate=30/1 ! avenc_mpeg1video gop-size=15 max-bframes=0 bitrate=10000 ! mpegtsmux ! curlhttpsink location=http://127.0.0.1:8081/yoursecret
```




## intel vaapi pipelines
camera rtsp mjpg > h264 udp rtp 
```sh
gst-launch-1.0 rtspsrc location=rtsp://10.0.0.11:8554/MCDE3000 latency=0 ! decodebin ! vaapih264enc ! h264parse ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=5000
```

udp rtp h264 > gldisplay:  latency is about 100ms
```sh
gst-launch-1.0 -v udpsrc port=5000 ! application/x-rtp,clock-rate=90000,payload=96 ! rtph264depay ! avdec_h264 ! videoconvert ! glimagesink
```

udp rtp h264 > mpeg1 > mpegts > http: latency is about 300ms
```sh
GST_DEBUG=3 gst-launch-1.0 -v udpsrc port=5000 ! application/x-rtp,clock-rate=90000,payload=96 ! rtph264depay ! vaapih264dec low-latency=true ! videorate ! video/x-raw,framerate=30/1 ! avenc_mpeg1video gop-size=15 max-bframes=0 bitrate=10000 ! mpegtsmux ! curlhttpsink location=http://127.0.0.1:8081/yoursecret
```
## namedpipe encode 

not tested

```sh
gst-launch-1.0 -v filesrc location='video_fifo' ! videoparse width=640 height=480 format=GST_VIDEO_FORMAT_YUY2 ! videoconver ! x264enc tune=zerolatency bitrate=500 speed-preset=superfast ! h264parse ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=5000
```

play YUV444 FULL HD file 

``` sh
gst-launch-1.0 -v filesrc location=size_1920x1080.yuv ! videoparse width=1920 height=1080 framerate=25/1 format=GST_VIDEO_FORMAT_Y444 ! videoconvert ! autovideosink
```

play YUV422 FULL HD file
```sh
gst-launch-1.0 -v filesrc location=size_1920x1080.yuv ! \
    videoparse width=1920 height=1080 framerate=25/1 format=GST_VIDEO_FORMAT_Y42B ! \
    videoconvert ! \
    autovideosink
```

play YUV422 FULL HD file 
```sh 
gst-launch-1.0 -v filesrc location=size_1920x1080.yuv ! \
    videoparse width=1920 height=1080 framerate=25/1 format=GST_VIDEO_FORMAT_Y42B ! \
    videoconvert ! \
    autovideosink
```

make PNG from YUV420
```sh
gst-launch-1.0 -v filesrc location=size_1920x1080.yuv ! \
    videoparse width=1920 height=1080 framerate=25/1 format=GST_VIDEO_FORMAT_Y42B ! \
    videoconvert ! \
    pngenc ! multifilesink location=img%03d.png
```

play MP4 FULL HD file
```sh
gst-launch-1.0 filesrc location=test.mp4 ! \
    decodebin name=dec ! \
    queue ! \
    videoconvert ! \
    autovideosink dec. ! \
    queue ! \
    audioconvert ! \
    audioresample ! \
    autoaudiosink
```

play MP3
```sh
gst-launch-1.0 filesrc location=test.mp3 ! decodebin ! playsink
```
play OGG
```
gst-launch-1.0 filesrc location=test.ogg ! decodebin ! playsink
```

play MP3 over UDP + RTP
sender: 
```sh
gst-launch-1.0 -v filesrc location=test.mp3 ! \
    decodebin ! \
    audioconvert ! \
    rtpL16pay ! \
    udpsink port=6969 host=192.168.1.42
```
receiver:
```sh 
gst-launch-1.0 -v udpsrc port=6969 \
    caps="application/x-rtp, media=(string)audio, format=(string)S32LE, \
    layout=(string)interleaved, clock-rate=(int)44100, channels=(int)2, payload=(int)0" ! \
    rtpL16depay ! playsink
```

play webcam video over UDP with h264 coding
sender
```sh 
gst-launch-1.0 v4l2src ! \
    'video/x-raw, width=640, height=480, framerate=30/1' ! \
    videoconvert ! \
    x264enc pass=qual quantizer=20 tune=zerolatency ! \
    rtph264pay ! \
    udpsink host=192.168.1.140 port=1234
```
receiver
```sh
gst-launch-1.0 udpsrc port=1234 ! \
    "application/x-rtp, payload=127" ! \
    rtph264depay ! \
    avdec_h264 ! \
    videoconvert  ! \
    xvimagesink sync=false
```

play RAW webcam video over UDP (+RTP) without any coding
sender
```
gst-launch-1.0 -v v4l2src ! 'video/x-raw, width=(int)640, height=(int)480, framerate=10/1' ! \
    videoconvert ! queue ! \
    rtpvrawpay ! queue ! \
    udpsink host=127.0.0.1 port=1234
```
receiver
```sh 
gst-launch-1.0 udpsrc port=1234 ! \
    "application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)RAW, \
    sampling=(string)YCbCr-4:2:2, depth=(string)8, width=(string)640, height=(string)480, \
    ssrc=(uint)1825678493, payload=(int)96, clock-base=(uint)4068866987, seqnum-base=(uint)24582" ! \
    rtpvrawdepay ! queue  ! videoconvert  ! autovideosink   
```

save RAW video from webcam to file
```sh 
gst-launch-1.0 -v v4l2src ! 'video/x-raw, width=(int)640, height=(int)480, framerate=10/1' ! videoconvert ! filesink location=out.yuv
```

play RAW video from file
```sh
gst-launch-1.0 filesrc location=out.yuv ! videoparse width=640 height=480 format=GST_VIDEO_FORMAT_YUY2 ! videoconvert ! autovideosink  
```
