#!/bin/bash

# Enhanced Network Manager for Qtile with improved rofi interface
# Uses the improved theme and better functionality

SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
THEME_FILE="$CONFIG_DIR/rofi-network-manager-improved.rasi"

# Check if improved theme exists, fallback to original if not
if [[ ! -f "$THEME_FILE" ]]; then
    THEME_FILE="$CONFIG_DIR/rofi-network-manager.rasi"
fi

get_network_status() {
    # Get current network status
    local wifi_status=$(nmcli -t -f WIFI g)
    local active_connection=$(nmcli -t -f NAME c show --active | head -1)
    
    if [[ "$wifi_status" == "enabled" ]] && [[ -n "$active_connection" ]]; then
        echo "connected"
    elif [[ "$wifi_status" == "enabled" ]]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

get_network_icon() {
    local status=$(get_network_status)
    case $status in
        "connected")
            echo "󰖩" # Connected WiFi
            ;;
        "enabled")
            echo "󰖪" # WiFi enabled but not connected
            ;;
        "disabled")
            echo "󰖭" # WiFi disabled
            ;;
        *)
            echo "󰈂" # Network error
            ;;
    esac
}

get_connection_info() {
    local wifi_status=$(nmcli -t -f WIFI g)
    
    if [[ "$wifi_status" == "disabled" ]]; then
        echo "WiFi Off"
        return
    fi
    
    # Get active connection details
    local active_connection=$(nmcli -t -f NAME c show --active | head -1)
    
    if [[ -z "$active_connection" ]]; then
        echo "Disconnected"
        return
    fi
    
    # Get signal strength for WiFi connections
    local signal_info=$(nmcli -f IN-USE,SSID,SIGNAL dev wifi | grep '^\*' | head -1)
    
    if [[ -n "$signal_info" ]]; then
        # Extract signal strength
        local signal=$(echo "$signal_info" | awk '{print $NF}')
        local ssid=$(echo "$signal_info" | awk '{for(i=2;i<NF;i++) printf "%s ", $i}' | sed 's/[[:space:]]*$//')
        
        # Clean up SSID - remove any artifacts
        ssid=$(echo "$ssid" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        if [[ "$signal" =~ ^[0-9]+$ ]]; then
            echo "$ssid"
        else
            echo "$ssid"
        fi
    else
        # Non-WiFi connection or fallback
        echo "$active_connection"
    fi
}

show_network_menu() {
    # Check if nmgui exists and is executable
    if [[ -x "$HOME/.local/bin/nmgui" ]]; then
        # Use the enhanced rofi theme
        export RASI_DIR="$THEME_FILE"
        "$HOME/.local/bin/nmgui"
    else
        # Fallback to simple network menu
        show_simple_network_menu
    fi
}

show_simple_network_menu() {
    local wifi_status=$(nmcli -t -f WIFI g)
    local options=""
    
    if [[ "$wifi_status" == "enabled" ]]; then
        options="󰖪 Scan & Connect\n󰖭 Disable WiFi\n󰑐 Connection Settings"
    else
        options="󰖩 Enable WiFi\n󰑐 Connection Settings"
    fi
    
    local selected=$(echo -e "$options" | rofi -dmenu -i -p "󰈀 Network" -theme "$THEME_FILE" -lines 3)
    
    case $selected in
        *"Scan & Connect"*)
            show_wifi_list
            ;;
        *"Enable WiFi"*)
            nmcli radio wifi on
            notify-send "Network" "WiFi enabled" -i network-wireless-on
            ;;
        *"Disable WiFi"*)
            nmcli radio wifi off
            notify-send "Network" "WiFi disabled" -i network-wireless-off
            ;;
        *"Connection Settings"*)
            if command -v nm-connection-editor &> /dev/null; then
                nm-connection-editor &
            else
                notify-send "Network" "NetworkManager GUI not available" -i dialog-error
            fi
            ;;
    esac
}

show_wifi_list() {
    # Scan for networks
    notify-send "Network" "Scanning for WiFi networks..." -i network-wireless -t 2000
    nmcli device wifi rescan
    
    # Get current active connection
    local current_ssid=$(nmcli -t -f NAME c show --active | head -1)
    
    # Get available networks - using a more reliable parsing method
    local networks_raw=$(nmcli -f SSID,SIGNAL,SECURITY,IN-USE device wifi list)
    local networks=""
    local connected_network=""
    
    # Parse networks line by line
    while IFS= read -r line; do
        # Skip header line
        if [[ "$line" =~ ^SSID ]]; then
            continue
        fi
        
        # Simple and reliable parsing approach
        # Split the line into an array
        local fields=($line)
        local num_fields=${#fields[@]}
        
        # Skip if not enough fields
        if [[ $num_fields -lt 3 ]]; then
            continue
        fi
        
        # IN-USE is always the last field (* or -)
        local in_use="${fields[$((num_fields-1))]}"
        
        # SECURITY is everything before IN-USE except SSID and SIGNAL
        # SIGNAL is always numeric
        local signal=""
        local signal_index=-1
        
        # Find the signal (numeric field)
        for ((i=1; i<num_fields-1; i++)); do
            if [[ "${fields[$i]}" =~ ^[0-9]+$ ]]; then
                signal="${fields[$i]}"
                signal_index=$i
                break
            fi
        done
        
        # If no numeric signal found, set to 0
        if [[ -z "$signal" ]]; then
            signal="0"
            signal_index=1
        fi
        
        # SSID is the first field
        local ssid="${fields[0]}"
        
        # SECURITY is everything between SIGNAL and IN-USE
        local security=""
        if [[ $signal_index -ge 0 && $((signal_index + 1)) -lt $((num_fields - 1)) ]]; then
            for ((i=$((signal_index + 1)); i<num_fields-1; i++)); do
                if [[ -n "$security" ]]; then
                    security="$security ${fields[$i]}"
                else
                    security="${fields[$i]}"
                fi
            done
        fi
        
        # Clean up fields
        ssid=$(echo "$ssid" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        # Skip empty or hidden SSIDs
        if [[ -z "$ssid" || "$ssid" == "--" ]]; then
            continue
        fi
        
        # Determine signal strength icon
        local icon="󰖠"
        if [[ "$signal" -ge 75 ]]; then
            icon="󰖩"
        elif [[ "$signal" -ge 50 ]]; then
            icon="󰖪"
        elif [[ "$signal" -ge 25 ]]; then
            icon="�"
        fi
        
        # Add security icon if needed
        local sec_icon=""
        if [[ "$security" != "--" && -n "$security" && "$security" != "0" && "$security" =~ (WPA|WEP) ]]; then
            sec_icon=" 󰌾"
        fi
        
        # Format network entry
        local network_entry="$icon $ssid ($signal%)$sec_icon"
        
        # Check if this is the currently connected network
        if [[ "$in_use" == "*" || "$ssid" == "$current_ssid" ]]; then
            connected_network="󰖩 $ssid ($signal%)$sec_icon [Connected]"
        else
            if [[ -n "$networks" ]]; then
                networks="$networks\n$network_entry"
            else
                networks="$network_entry"
            fi
        fi
        
    done <<< "$networks_raw"
    
    # Combine connected network at top with other networks
    local final_networks=""
    if [[ -n "$connected_network" ]]; then
        final_networks="$connected_network"
        if [[ -n "$networks" ]]; then
            final_networks="$final_networks\n$networks"
        fi
    else
        final_networks="$networks"
    fi
    
    if [[ -z "$final_networks" ]]; then
        notify-send "Network" "No WiFi networks found" -i network-wireless-off
        return
    fi
    
    local selected=$(echo -e "$final_networks" | rofi -dmenu -i -p "󰖩 Select Network" -theme "$THEME_FILE" -lines 10)
    
    if [[ -n "$selected" ]]; then
        # Extract SSID from selection - handle connected networks specially
        local ssid=""
        if [[ "$selected" =~ \[Connected\] ]]; then
            # Already connected, show options for current network
            ssid=$(echo "$selected" | sed 's/^󰖩 //' | sed 's/ ([0-9]*%).*$//')
            show_connected_options "$ssid"
            return
        else
            # Extract SSID from regular network entry
            ssid=$(echo "$selected" | sed 's/^[󰖩󰖪󰖡󰖠] //' | sed 's/ ([0-9]*%).*$//')
        fi
        
        # Attempt to connect with smart password handling
        connect_to_network_smart "$ssid"
    fi
}

show_connected_options() {
    local ssid="$1"
    local options="󰖩 Stay Connected\n󰖭 Disconnect\n󰑓 Forget Network\n󰅙 Show QR Code"
    
    local selected=$(echo -e "$options" | rofi -dmenu -i -p "Connected to: $ssid" -theme "$THEME_FILE" -lines 4)
    
    case $selected in
        *"Stay Connected"*)
            # Do nothing
            ;;
        *"Disconnect"*)
            nmcli connection down "$ssid"
            notify-send "Network" "Disconnected from $ssid" -i network-wireless-off
            ;;
        *"Forget Network"*)
            nmcli connection delete "$ssid"
            notify-send "Network" "Forgot network $ssid" -i network-wireless-off
            ;;
        *"Show QR Code"*)
            # Generate QR code if qrencode is available
            if command -v qrencode &> /dev/null; then
                # Try different ways to get the password
                local password=""
                
                # Try to get password from connection profile
                password=$(nmcli -s -g 802-11-wireless-security.psk connection show "$ssid" 2>/dev/null || echo "")
                
                # If that fails, try alternative field names
                if [[ -z "$password" ]]; then
                    password=$(nmcli -s -g wifi-sec.psk connection show "$ssid" 2>/dev/null || echo "")
                fi
                
                # If still no password, try to get it from system connections
                if [[ -z "$password" ]]; then
                    password=$(nmcli -s -g 802-11-wireless-security.psk connection show id "$ssid" 2>/dev/null || echo "")
                fi
                
                if [[ -n "$password" ]]; then
                    echo "WIFI:T:WPA;S:$ssid;P:$password;;" | qrencode -o /tmp/wifi_qr.png
                    if command -v feh &> /dev/null; then
                        feh /tmp/wifi_qr.png &
                    elif command -v eog &> /dev/null; then
                        eog /tmp/wifi_qr.png &
                    fi
                    notify-send "Network" "QR Code generated for $ssid" -i network-wireless
                else
                    notify-send "Network" "Cannot generate QR code - password not accessible" -i dialog-information -t 3000
                fi
            else
                notify-send "Network" "QR code generation requires qrencode package" -i dialog-error
            fi
            ;;
    esac
}

# Smart connection function that handles saved profiles and password prompting
connect_to_network_smart() {
    local ssid="$1"
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        echo "Attempting connection to $ssid (attempt $attempt/$max_attempts)" >&2
        
        # Check if we have a saved profile for this network
        local saved_profile=$(nmcli -t -f NAME connection show | grep -F "$ssid" | head -1)
        
        if [[ -n "$saved_profile" ]]; then
            echo "Found saved profile: $saved_profile" >&2
            # Try to connect using saved profile first
            if connect_with_saved_profile "$ssid"; then
                return 0
            else
                echo "Saved profile connection failed, prompting for password" >&2
                # If saved profile fails, delete it and prompt for new password
                nmcli connection delete "$ssid" 2>/dev/null || true
            fi
        fi
        
        # Check if network requires password
        local security=$(nmcli -f SSID,SECURITY device wifi list | grep -F "$ssid" | head -1)
        local security_type=""
        
        if [[ "$security" =~ WPA ]]; then
            security_type="WPA"
        elif [[ "$security" =~ WEP ]]; then
            security_type="WEP"
        elif [[ "$security" =~ "--" ]] || [[ -z "$security" ]]; then
            security_type="OPEN"
        else
            security_type="WPA"  # Default to WPA for unknown security
        fi
        
        if [[ "$security_type" != "OPEN" ]]; then
            # Network requires password
            local password_prompt="Password for $ssid"
            if [[ $attempt -gt 1 ]]; then
                password_prompt="Password for $ssid (attempt $attempt/$max_attempts)"
            fi
            
            local password=$(rofi -dmenu -password -i -p "$password_prompt" -theme "$THEME_FILE" -lines 0)
            
            if [[ -z "$password" ]]; then
                echo "No password provided, cancelling connection" >&2
                return 1
            fi
            
            if connect_to_network_with_password "$ssid" "$password"; then
                return 0
            else
                echo "Connection failed with provided password" >&2
                ((attempt++))
                if [[ $attempt -le $max_attempts ]]; then
                    # Show error and ask if they want to retry
                    local retry_options="🔄 Try Again\n❌ Cancel"
                    local retry_choice=$(echo -e "$retry_options" | rofi -dmenu -i -p "Connection failed. Retry?" -theme "$THEME_FILE" -lines 2)
                    
                    if [[ "$retry_choice" =~ "Cancel" ]] || [[ -z "$retry_choice" ]]; then
                        echo "User cancelled retry" >&2
                        return 1
                    fi
                else
                    notify-send "Network" "❌ Failed to connect to $ssid after $max_attempts attempts" -i network-wireless-off -t 5000
                    return 1
                fi
            fi
        else
            # Open network
            if connect_to_network_with_password "$ssid"; then
                return 0
            else
                echo "Failed to connect to open network $ssid" >&2
                return 1
            fi
        fi
    done
    
    # If we get here, all attempts failed
    # Ask user if they want to go back to the network list
    local options="🔄 Try Another Network\n❌ Cancel"
    local choice=$(echo -e "$options" | rofi -dmenu -i -p "Connection failed. What next?" -theme "$THEME_FILE" -lines 2)
    
    if [[ "$choice" =~ "Try Another Network" ]]; then
        echo "Returning to network list" >&2
        show_wifi_list
    fi
    
    return 1
}

# Connect using saved profile
connect_with_saved_profile() {
    local ssid="$1"
    
    notify-send "Network" "Connecting to $ssid..." -i network-wireless -t 3000
    
    # Try to connect using the saved profile
    if nmcli connection up "$ssid" 2>/dev/null; then
        notify-send "Network" "✅ Connected to $ssid" -i network-wireless-on -t 3000
        return 0
    else
        echo "Saved profile connection failed for $ssid" >&2
        return 1
    fi
}

# Connect with password (creates new profile)
connect_to_network_with_password() {
    local ssid="$1"
    local password="$2"
    
    notify-send "Network" "Connecting to $ssid..." -i network-wireless -t 3000
    
    # First, try to delete any existing connection profile for this SSID to avoid conflicts
    nmcli connection delete "$ssid" 2>/dev/null || true
    
    local success=false
    local error_message=""
    
    if [[ -n "$password" ]]; then
        # Method 1: Simple connection (works for most cases)
        if nmcli device wifi connect "$ssid" password "$password" 2>/tmp/nmcli_error.log; then
            success=true
        else
            error_message=$(cat /tmp/nmcli_error.log 2>/dev/null || echo "Unknown error")
            
            # Method 2: Create explicit WPA2-PSK profile
            if nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" \
               wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password" \
               wifi-sec.proto rsn wifi-sec.pairwise ccmp 2>/tmp/nmcli_error2.log; then
                
                if nmcli connection up "$ssid" 2>/tmp/nmcli_error3.log; then
                    success=true
                else
                    nmcli connection delete "$ssid" 2>/dev/null || true
                    error_message=$(cat /tmp/nmcli_error3.log 2>/dev/null || echo "Failed to activate connection")
                fi
            else
                error_message=$(cat /tmp/nmcli_error2.log 2>/dev/null || echo "Failed to create connection profile")
            fi
        fi
    else
        # For open networks
        if nmcli device wifi connect "$ssid" 2>/tmp/nmcli_error.log; then
            success=true
        else
            error_message=$(cat /tmp/nmcli_error.log 2>/dev/null || echo "Unknown error")
            
            # Try creating an open connection profile
            if nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" 2>/tmp/nmcli_error2.log; then
                if nmcli connection up "$ssid" 2>/tmp/nmcli_error3.log; then
                    success=true
                else
                    nmcli connection delete "$ssid" 2>/dev/null || true
                    error_message=$(cat /tmp/nmcli_error3.log 2>/dev/null || echo "Failed to activate connection")
                fi
            else
                error_message=$(cat /tmp/nmcli_error2.log 2>/dev/null || echo "Failed to create connection profile")
            fi
        fi
    fi
    
    # Clean up temp files
    rm -f /tmp/nmcli_error*.log
    
    # Report result
    if [[ "$success" == true ]]; then
        notify-send "Network" "✅ Connected to $ssid" -i network-wireless-on -t 3000
        return 0
    else
        # Provide helpful error message
        local user_message="❌ Failed to connect to $ssid"
        if [[ "$error_message" =~ "802-11-wireless-security.key-mgmt" ]]; then
            user_message="❌ Connection failed: Invalid security settings"
        elif [[ "$error_message" =~ "password" ]] || [[ "$error_message" =~ "authentication" ]]; then
            user_message="❌ Connection failed: Check password"
        elif [[ "$error_message" =~ "timeout" ]]; then
            user_message="❌ Connection failed: Network timeout"
        fi
        
        notify-send "Network" "$user_message" -i network-wireless-off -t 5000
        echo "Connection error: $error_message" >&2
        return 1
    fi
}

# Legacy connect function - kept for compatibility
connect_to_network() {
    local ssid="$1"
    local password="$2"
    
    # Use the smart connection function instead
    if [[ -n "$password" ]]; then
        connect_to_network_with_password "$ssid" "$password"
    else
        connect_to_network_smart "$ssid"
    fi
}

case "$1" in
    "status")
        get_network_status
        ;;
    "icon")
        get_network_icon
        ;;
    "info")
        get_connection_info
        ;;
    "menu")
        show_network_menu
        ;;
    "simple-menu")
        show_simple_network_menu
        ;;
    *)
        echo "Usage: $0 {status|icon|info|menu|simple-menu}"
        exit 1
        ;;
esac
