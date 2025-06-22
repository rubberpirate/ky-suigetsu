#!/bin/bash
# qtile_workspace_switcher.sh
# Usage: ./qtile_workspace_switcher.sh next|prev

# State file to track current workspace
STATE_FILE="/tmp/qtile_current_workspace"

# All available workspaces (based on your qtile config)
workspaces=("1" "2" "3" "4" "5" "6" "7")

# Get current workspace index from state file, or default to 0
if [[ -f "$STATE_FILE" ]]; then
    current_index=$(cat "$STATE_FILE")
    # Validate the index
    if ! [[ "$current_index" =~ ^[0-9]+$ ]] || [[ $current_index -ge ${#workspaces[@]} ]]; then
        current_index=0
    fi
else
    current_index=0
fi

# Calculate next workspace based on argument
if [[ "$1" == "next" ]]; then
    next_index=$(( (current_index + 1) % ${#workspaces[@]} ))
elif [[ "$1" == "prev" ]]; then
    next_index=$(( (current_index - 1 + ${#workspaces[@]}) % ${#workspaces[@]} ))
else
    echo "Usage: $0 next|prev"
    echo "Current workspace: ${workspaces[$current_index]} (index: $current_index)"
    echo "Available workspaces: ${workspaces[*]}"
    exit 1
fi

target_workspace="${workspaces[$next_index]}"

# Debug output (comment out when working)
echo "Current: ${workspaces[$current_index]} (index: $current_index)"
echo "Switching to: $target_workspace (index: $next_index)"

# Switch to the target workspace using xdotool
if command -v xdotool &> /dev/null; then
    xdotool key super+$target_workspace
    # Update state file with new index
    echo "$next_index" > "$STATE_FILE"
    echo "Switched to workspace $target_workspace"
else
    echo "Error: xdotool not found. Please install it:"
    echo "sudo apt install xdotool"
    exit 1
fi
