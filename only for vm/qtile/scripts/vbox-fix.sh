#!/bin/bash
# VirtualBox Qtile Fix Script

echo "Fixing Qtile for VirtualBox compatibility..."

# Kill compositor if running
pkill picom
echo "Stopped picom compositor"

# Kill problematic applications
pkill eww
pkill volctl
echo "Stopped problematic applications"

# Restart Qtile
qtile cmd-obj -o cmd -f restart
echo "Restarted Qtile"

# Set solid terminal background
if command -v alacritty &> /dev/null; then
    echo "To fix transparent terminal, edit ~/.config/alacritty/alacritty.yml"
    echo "Set: window.opacity: 1.0"
fi

echo "VirtualBox compatibility fixes applied!"
echo "If terminal is still transparent, restart your terminal application."
