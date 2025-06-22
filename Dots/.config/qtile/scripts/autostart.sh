#!/bin/bash

export PATH="/home/rubberpirate/.local/bin:$PATH"

picom -b &
eww daemon &
volctl &
nm-applet &
libinput-gestures-setup restart
flameshot &
blueman-applet &
plank &
dunst &
mkfifo /tmp/vol-icon && ~/.config/qtile/scripts/vol_icon.sh &
