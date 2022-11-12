#!/bin/bash
# RECV RTP stream raspberry pi cam

PORT="5200"

usage() {
    echo "Usage: $0"
    echo "Options"
    echo "  -p: Port. Default=$PORT"
}

# Get CLI options/arguments.
while getopts "u:p:h?" opt; do
  case $opt in
    p) # port
      PORT=${OPTARG}
      ;;
    h) # Print help information.
      usage && exit 0
      ;;
  esac
done


gst-launch-1.0 \
    udpsrc port=$PORT !\
    application/x-rtp, media=video, clock-rate=90000, payload=96 !\
    rtpjpegdepay !\
    jpegdec !\
    videoconvert !\
    autovideosink
