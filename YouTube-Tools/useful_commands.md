## Normalize volume of track 
ffmpeg -i raw.flac.flac -af loudnorm out_tw.flac

## Resize folder full of videos
mogrify -resize 1024x768 *.jpg
