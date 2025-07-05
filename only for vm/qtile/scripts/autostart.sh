#!/bin/bash

export PATH="/home/rubberpirate/.local/bin:$PATH"

# Detect if running in VirtualBox
if [ "$(systemd-detect-virt)" = "oracle" ]; then
    echo "VirtualBox detected - using compatibility mode"
    # Skip picom in VirtualBox as it causes transparency issues
    # picom -b &
else
    # Run picom on real hardware
    picom -b &
fi

# These should work fine in VirtualBox
nm-applet &
libinput-gestures-setup restart
flameshot &
blueman-applet &
plank &
dunst &

# Skip problematic applications in VirtualBox
if [ "$(systemd-detect-virt)" != "oracle" ]; then
    eww daemon &
    volctl &
    mkfifo /tmp/vol-icon && ~/.config/qtile/scripts/vol_icon.sh &
fi
