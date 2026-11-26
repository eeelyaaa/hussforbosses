#!/usr/bin/env bash
# Cuts a generated 4x4 icon sheet into icons: hardens the alpha (drops the soft glow), adds the style guide's white rim
# by dilating the alpha (no pixel of the icon is redrawn), then crops each grid cell to its content.
# usage: cut_icons.sh sheet.png outdir name1 name2 ... (row by row) ; GRID=4 by default
set -e
sheet=$1; out=$2; shift 2; G=${GRID:-4}
mkdir -p "$out"
D=$(printf 'dilation,%.0s' $(seq 1 ${RIM:-14})); D=${D%,}
ffmpeg -v error -y -i "$sheet" -filter_complex "[0]format=rgba,lut=a='clip((val-150)*5,0,255)',split=2[a][b];[a]alphaextract,$D,gblur=1.2,lut='clip((val-110)*6,0,255)'[m];[b]split[b1][b2];[b1]drawbox=c=white:t=fill,format=rgba[w];[w][m]alphamerge[rim];[rim][b2]overlay=format=auto" "$out/_rimmed.png"
W=$(ffprobe -v error -show_entries stream=width -of csv=p=0 "$out/_rimmed.png"); C=$((W/G)); i=0
for n in "$@"; do
  cx=$(( (i%G)*C )); cy=$(( (i/G)*C ))
  cd_=$(ffmpeg -v info -loop 1 -i "$out/_rimmed.png" -vf "crop=$C:$C:$cx:$cy,alphaextract,cropdetect=limit=24:round=2:reset=0" -frames:v 4 -f null - 2>&1 | grep -o 'crop=[0-9:]*' | tail -1)
  IFS=: read w h x y <<<"${cd_#crop=}"
  ffmpeg -v error -y -i "$out/_rimmed.png" -vf "crop=$w:$h:$((cx+x)):$((cy+y))" "$out/$n.png"
  echo "$n $w $h"
  i=$((i+1))
done
rm "$out/_rimmed.png"
