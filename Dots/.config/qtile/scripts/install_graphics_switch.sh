#!/bin/bash

# Installation script for graphics switching functionality
echo "Setting up graphics switching integration..."

# Check if envycontrol is installed
if ! command -v envycontrol &> /dev/null; then
    echo "envycontrol not found. Installing..."
    
    # Check if pip is available
    if command -v pip &> /dev/null; then
        pip install envycontrol
    elif command -v pip3 &> /dev/null; then
        pip3 install envycontrol
    else
        echo "Error: pip not found. Please install pip first."
        echo "You can install envycontrol manually with: pip install envycontrol"
        exit 1
    fi
else
    echo "envycontrol is already installed."
fi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Warning: rofi not found. Please install rofi for the graphics switching menu."
    echo "Install with: sudo pacman -S rofi (Arch) or sudo apt install rofi (Ubuntu/Debian)"
fi

# Check if notify-send is available
if ! command -v notify-send &> /dev/null; then
    echo "Warning: notify-send not found. Please install libnotify for notifications."
    echo "Install with: sudo pacman -S libnotify (Arch) or sudo apt install libnotify-bin (Ubuntu/Debian)"
fi

echo "Setup complete!"
echo ""
echo "Usage:"
echo "- Click on the graphics widget in the bar to open the switching menu"
echo "- Select integrated, hybrid, or nvidia mode"
echo "- Reboot after switching for changes to take effect"
echo ""
echo "Note: Graphics switching requires administrative privileges."
