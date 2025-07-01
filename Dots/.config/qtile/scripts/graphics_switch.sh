#!/bin/bash

# Graphics switching script using envycontrol
# Requires envycontrol to be installed: pip install envycontrol

get_current_mode() {
    # Get current graphics mode
    current_mode=$(envycontrol --query 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [ -z "$current_mode" ]; then
        echo "unknown"
    else
        echo "$current_mode"
    fi
}

show_rofi_menu() {
    # Create rofi menu for graphics switching
    current_mode=$(get_current_mode)
    
    # Options with icons and current mode indicator
    if [ "$current_mode" = "integrated" ]; then
        options="󰍹 Integrated (Current)\n󰘚 Hybrid\n󰢮 NVIDIA"
    elif [ "$current_mode" = "hybrid" ]; then
        options="󰍹 Integrated\n󰘚 Hybrid (Current)\n󰢮 NVIDIA"
    elif [ "$current_mode" = "nvidia" ]; then
        options="󰍹 Integrated\n󰘚 Hybrid\n󰢮 NVIDIA (Current)"
    else
        options="󰍹 Integrated\n󰘚 Hybrid\n󰢮 NVIDIA"
    fi
    
    selected=$(echo -e "$options" | rofi -dmenu -i -p "󰾆 Graphics Mode" -theme ~/.config/rofi/launcher.rasi -lines 3 -width 25)
    
    if [ -z "$selected" ]; then
        exit 0
    fi
    
    # Extract the mode from the selection
    case $selected in
        *"Integrated"*)
            target_mode="integrated"
            ;;
        *"Hybrid"*)
            target_mode="hybrid"
            ;;
        *"NVIDIA"*)
            target_mode="nvidia"
            ;;
        *)
            exit 0
            ;;
    esac
    
    if [ "$target_mode" = "$current_mode" ]; then
        notify-send "Graphics Switch" "Already using $target_mode graphics mode" -i video-display -t 3000
        exit 0
    fi
    
    # Show confirmation dialog
    confirm_options="󰄬 Yes, switch and reboot\n󰜺 No, cancel"
    confirm=$(echo -e "$confirm_options" | rofi -dmenu -i -p "󰍹 Switch to $target_mode?" -theme ~/.config/rofi/launcher.rasi -lines 2 -width 30)
    
    if [[ "$confirm" != *"Yes"* ]]; then
        exit 0
    fi
    
    # Use sudo instead of pkexec for better compatibility
    case $target_mode in
        "integrated")
            if sudo -A envycontrol -s integrated 2>/dev/null || \
               pkexec envycontrol -s integrated 2>/dev/null || \
               (notify-send "Authentication Required" "Please enter your password in the terminal" -i dialog-password -t 3000 && sudo envycontrol -s integrated); then
                notify-send "Graphics Switch" "Switched to integrated graphics. Reboot required." -i video-display -t 8000
            else
                notify-send "Graphics Switch" "Failed to switch to integrated graphics. Check your permissions." -i dialog-error -t 5000
            fi
            ;;
        "hybrid")
            if sudo -A envycontrol -s hybrid 2>/dev/null || \
               pkexec envycontrol -s hybrid 2>/dev/null || \
               (notify-send "Authentication Required" "Please enter your password in the terminal" -i dialog-password -t 3000 && sudo envycontrol -s hybrid); then
                notify-send "Graphics Switch" "Switched to hybrid graphics. Reboot required." -i video-display -t 8000
            else
                notify-send "Graphics Switch" "Failed to switch to hybrid graphics. Check your permissions." -i dialog-error -t 5000
            fi
            ;;
        "nvidia")
            if sudo -A envycontrol -s nvidia 2>/dev/null || \
               pkexec envycontrol -s nvidia 2>/dev/null || \
               (notify-send "Authentication Required" "Please enter your password in the terminal" -i dialog-password -t 3000 && sudo envycontrol -s nvidia); then
                notify-send "Graphics Switch" "Switched to NVIDIA graphics. Reboot required." -i video-display -t 8000
            else
                notify-send "Graphics Switch" "Failed to switch to NVIDIA graphics. Check your permissions." -i dialog-error -t 5000
            fi
            ;;
    esac
}

get_graphics_icon() {
    mode=$(get_current_mode)
    case $mode in
        "integrated")
            echo "󰍹"  # CPU icon for integrated
            ;;
        "hybrid")
            echo "󰘚"  # Switch icon for hybrid
            ;;
        "nvidia"|"discrete")
            echo "󰢮"  # GPU icon for NVIDIA
            ;;
        *)
            echo "󰟀"  # Question mark for unknown
            ;;
    esac
}

case "$1" in
    "current")
        get_current_mode
        ;;
    "icon")
        get_graphics_icon
        ;;
    "menu")
        show_rofi_menu
        ;;
    *)
        echo "Usage: $0 {current|icon|menu}"
        exit 1
        ;;
esac
