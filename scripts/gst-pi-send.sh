#!/bin/bash
# RTP stream raspberry pi cam

HOST="127.0.0.1"
PORT="5200"

usage() {
    echo "Usage: $0"
    echo "Options"
    echo "  -u: Target URI/Host. Default=$HOST"
    echo "  -p: Target Port. Default=$PORT"
}

# Get CLI options/arguments.
while getopts "u:p:h?" opt; do
  case $opt in
    u) # uri|host
      HOST=${OPTARG}
      ;;
    p) # port
      PORT=${OPTARG}
      ;;
    h) # Print help information.
      usage && exit 0
      ;;
  esac
done


gst-launch-1.0 \
    v4l2src device=/dev/video0 num-buffers=-1 !\
    video/x-raw, width=640, height=480, framerate=30/1 !\
    videoconvert !\
    jpegenc !\
    rtpjpegpay !\
    udpsink host=$HOST port=$PORT
