#!/bin/bash

record_axis_help() {
  echo "$0 [OPTION]"
  echo "  I/O"
  echo "    --in: remote location of axis camera"
  echo "    --out: prefix for output video file"
  echo "    --split-time: split video for each time (default: 86400 [sec])"
  echo "    --max-file: Maximum number of files to keep on disk. Once the maximum is reached,old files start to be deleted to make room for new ones (default: 0)"
  echo "  Auth"
  echo "    --id: authentication user id"
  echo "    --pass: authentication user password"
  echo "  Quality"
  echo "    --resolution: video resolution (default 1280x1080)"
  echo "    --rate: video rate (defualt: 2)"
  echo "    --quality: quality for encoding to h264 (default: 21)"
  echo "  Other"
  echo "    --dry-run: echo command instead of execute"
}


record_axis() {
  SOUP_OPTION="is-live=true"
  ADDRESS="localhost"
  RESOLUTION="1280x1024"
  RATE="2"
  QUALITY="21"
  OUT="out"
  CMD="exec"
  SPLIT_TIME="0"
  MAX_FILE="0"
  #
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --in|-i)
        ADDRESS=$2
        shift
        ;;
      --out|-o)
        OUT=$(readlink -f $2)
        shift
        ;;
      --max-file)
        MAX_FILE=$2
        shift
        ;;
      --split-time)
        SPLIT_TIME=$2
        shift
        ;;
      --id)
        SOUP_OPTION="$SOUP_OPTION user-id=$2"
        shift
        ;;
      --pass)
        SOUP_OPTION="$SOUP_OPTION user-pw=$2"
        shift
        ;;
      --resolution)
        RESOLUTION=$2
        shift
        ;;
      --rate|-r)
        RATE=$2
        shift
        ;;
      --quality|-q)
        QUALITY=$2
        shift
        ;;
      --dry-run|-n)
        CMD="echo"
        shift
        ;;
      --help|-h)
        record_axis_help
        return 1
        ;;
      *)
        shift
        ;;
    esac
  done
  #
  local location="http://$ADDRESS/axis-cgi/mjpg/video.cgi?resolution=$RESOLUTION"
  local max_size_time=$(($SPLIT_TIME * 1000 * 1000 * 1000))
  #
  echo "input: $location"
  echo "output: $OUT"
  echo "max_size_time: $max_size_time"
  echo "max_file: $MAX_FILE"
  #
  $CMD gst-launch-1.0 -v\
       souphttpsrc location=${location} ${SOUP_OPTION} !\
       queue !\
       multipartdemux !\
       image/jpeg,framerate=\(fraction\)${RATE}/1 !\
       jpegparse !\
       jpegdec !\
       videoconvert !\
       x264enc pass=quant quantizer=$QUALITY !\
       splitmuxsink location="${OUT}_%05d.mp4" max-size-time=${max_size_time} max-files=${MAX_FILE} muxer=mp4mux
}

record_axis $@
