#!/bin/bash

# Apply wallpaper using wal
wal -b 282738 -i ~/Wallpaper/a3.png &&

# Start picom
picom --config ~/.config/picom/picom.conf &

# Start dunst notification daemon
dunst &

# Start plank dock
plank &
