#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Function to install packages with error handling
install_pacman_packages() {
    local packages=("$@")
    print_status "Installing packages: ${packages[*]}"
    
    if ! sudo pacman -S --noconfirm --needed "${packages[@]}"; then
        print_error "Failed to install pacman packages: ${packages[*]}"
        exit 1
    fi
    
    # Verify installation
    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            print_error "Package verification failed: $package"
            exit 1
        fi
    done
    
    print_status "Successfully installed: ${packages[*]}"
}

# Function to install AUR packages with error handling
install_yay_packages() {
    local packages=("$@")
    print_status "Installing AUR packages: ${packages[*]}"
    
    if ! yay -S --noconfirm --needed "${packages[@]}"; then
        print_error "Failed to install AUR packages: ${packages[*]}"
        exit 1
    fi
    
    # Verify installation
    for package in "${packages[@]}"; do
        if ! yay -Qi "$package" &>/dev/null; then
            print_error "AUR package verification failed: $package"
            exit 1
        fi
    done
    
    print_status "Successfully installed AUR packages: ${packages[*]}"
}

# Function to copy configuration files
install_config() {
    local config_name="$1"
    local source_path="$2"
    local target_path="$3"

    # Verify source exists
    if [[ ! -e "$source_path" ]]; then
        print_error "Source configuration not found: $source_path"
        return 1
    fi

    print_status "Installing $config_name configuration..."
    
    # Remove existing config if present
    if [[ -e "$target_path" ]]; then
        rm -rf "$target_path"
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Copy new config
    if ! cp -r "$source_path" "$target_path"; then
        print_error "Failed to install $config_name configuration"
        return 1
    fi
    
    print_status "$config_name configuration installed successfully"
}

# Introduction & Warning
clear
print_header "╔══════════════════════════════════════╗"
print_header "║     Ky-Suigetsu Qtile Setup!        ║"
print_header "╚══════════════════════════════════════╝"
echo
print_warning "This script requires sudo privileges for system package installation."
print_warning "Please ensure you're available during installation for any prompts."
echo
sleep 3

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch Linux and requires pacman!"
    exit 1
fi

# Check internet connectivity
print_status "Checking internet connectivity..."
if ! ping -c 1 archlinux.org &> /dev/null; then
    print_error "No internet connection detected! Please ensure you have internet access."
    print_error "You may need to configure your network connection first."
    exit 1
fi
print_status "Internet connectivity confirmed"

# Verify we're in the correct directory structure
if [[ ! -d "./Dots" ]]; then
    print_error "Dots directory not found! Please run this script from the ky-suigetsu repository root."
    print_error "Expected structure: ky-suigetsu/Dots/"
    exit 1
fi

print_status "Repository structure verified"

# System update 
print_status "Performing full system update..."
if ! sudo pacman --noconfirm -Syu; then
    print_error "System update failed!"
    exit 1
fi
print_status "System update completed"
sleep 2

# Install Git if not present 
print_status "Ensuring git is installed..."
install_pacman_packages git
sleep 1

# Install/Check Yay AUR helper
print_status "Checking for yay AUR helper..."
if ! command -v yay &> /dev/null; then
    print_status "Installing yay AUR helper..."
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    if ! git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"; then
        print_error "Failed to clone yay repository"
        exit 1
    fi
    
    # Build and install yay
    if ! (cd "$temp_dir/yay" && makepkg -si --noconfirm); then
        print_error "Failed to build/install yay"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify yay installation
    if ! command -v yay &> /dev/null; then
        print_error "Yay installation verification failed"
        exit 1
    fi
    
    print_status "Yay installed successfully"
else
    print_status "Yay already installed"
fi
sleep 1

# GPU Driver Selection
echo
print_header "GPU Driver Configuration"
echo "Please select your GPU type:"
echo "1) NVIDIA (will install DKMS drivers)"
echo "2) AMD"
echo "3) Intel"
echo "4) Skip driver installation"
echo
read -p "Enter your choice (1-4) [default: 4]: " gpu_choice

case $gpu_choice in
    1)
        print_status "Installing NVIDIA DKMS drivers..."
        GPU_DRIVERS=("nvidia-dkms" "nvidia-utils" "nvidia-settings" "linux-headers")
        ;;
    2)
        print_status "Installing AMD drivers..."
        GPU_DRIVERS=("xf86-video-amdgpu")
        ;;
    3)
        print_status "Installing Intel drivers..."
        GPU_DRIVERS=("xf86-video-intel")
        ;;
    *)
        print_status "Skipping GPU driver installation"
        GPU_DRIVERS=()
        ;;
esac

# Install base packages
BASE_PACKAGES=(
    "base-devel"
    "xorg-server"
    "xorg-xinit"
    "xorg-xbacklight"
    "xorg-xsetroot"
)

if [[ ${#GPU_DRIVERS[@]} -gt 0 ]]; then
    BASE_PACKAGES+=("${GPU_DRIVERS[@]}")
fi

install_pacman_packages "${BASE_PACKAGES[@]}"

# Install window manager and core utilities (X11 only)
QTILE_PACKAGES=(
    "qtile"
    "qtile-extras"
    "python-psutil"
    "python-dbus-next"
    "python-iwlib"
    "python-pulsectl-asyncio"
    "python-plyer"
)

install_yay_packages "${QTILE_PACKAGES[@]}"

# Install terminal and shell
TERMINAL_PACKAGES=(
    "kitty"
    "zsh"
    "starship"
)

install_yay_packages "${TERMINAL_PACKAGES[@]}"

# Install audio system
AUDIO_PACKAGES=(
    "pipewire"
    "pipewire-alsa"
    "pipewire-jack"
    "pipewire-pulse"
    "wireplumber"
    "pavucontrol"
    "pulsemixer"
    "brightnessctl"
)

install_yay_packages "${AUDIO_PACKAGES[@]}"

# Install compositor and effects
COMPOSITOR_PACKAGES=(
    "picom"
    "dunst"
    "rofi"
    "nitrogen"
    "feh"
    "flameshot"
)

install_yay_packages "${COMPOSITOR_PACKAGES[@]}"

# Install media and utilities
UTILITY_PACKAGES=(
    "ranger"
    "htop"
    "fastfetch"
    "neovim"
    "bat"
)

install_yay_packages "${UTILITY_PACKAGES[@]}"

# Install additional packages
ADDITIONAL_PACKAGES=(
    "plank"
    "python-pywal"
    "libinput-gestures"
    "xsettingsd"
)

install_yay_packages "${ADDITIONAL_PACKAGES[@]}"

# Install fonts
FONT_PACKAGES=(
    "ttf-dejavu"
    "ttf-liberation"
    "ttf-nerd-fonts-symbols-mono"
    "otf-hasklig-nerd"
    "ttf-material-design-icons-extended"
    "ttf-noto-sans-mono-vf"
)

install_yay_packages "${FONT_PACKAGES[@]}"

# Install configurations from Dots directory
print_status "Installing configuration files..."

# Main qtile config
if [[ -d "./Dots/.config/qtile" ]]; then
    install_config "Qtile" "./Dots/.config/qtile" "$HOME/.config/qtile"
fi

# Kitty terminal
if [[ -d "./Dots/.config/kitty" ]]; then
    install_config "Kitty" "./Dots/.config/kitty" "$HOME/.config/kitty"
fi

# Rofi launcher
if [[ -d "./Dots/.config/rofi" ]]; then
    install_config "Rofi" "./Dots/.config/rofi" "$HOME/.config/rofi"
fi

# Dunst notifications
if [[ -d "./Dots/.config/dunst" ]]; then
    install_config "Dunst" "./Dots/.config/dunst" "$HOME/.config/dunst"
fi

# Picom compositor
if [[ -d "./Dots/.config/picom" ]]; then
    install_config "Picom" "./Dots/.config/picom" "$HOME/.config/picom"
fi

# Plank dock
if [[ -d "./Dots/.config/plank" ]]; then
    install_config "Plank" "./Dots/.config/plank" "$HOME/.config/plank"
fi

# Ranger file manager
if [[ -d "./Dots/.config/ranger" ]]; then
    install_config "Ranger" "./Dots/.config/ranger" "$HOME/.config/ranger"
fi

# Fastfetch system info
if [[ -d "./Dots/.config/fastfetch" ]]; then
    install_config "Fastfetch" "./Dots/.config/fastfetch" "$HOME/.config/fastfetch"
fi

# Flameshot screenshots
if [[ -d "./Dots/.config/flameshot" ]]; then
    install_config "Flameshot" "./Dots/.config/flameshot" "$HOME/.config/flameshot"
fi

# Bat syntax highlighter
if [[ -d "./Dots/.config/bat" ]]; then
    install_config "Bat" "./Dots/.config/bat" "$HOME/.config/bat"
fi

# Zsh shell config
if [[ -d "./Dots/.config/zsh" ]]; then
    install_config "Zsh config" "./Dots/.config/zsh" "$HOME/.config/zsh"
fi

# Copy .zshrc to home directory
if [[ -f "./Dots/.zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" ]]; then
        rm -f "$HOME/.zshrc"
    fi
    if ! cp "./Dots/.zshrc" "$HOME/.zshrc"; then
        print_error "Failed to install .zshrc"
        exit 1
    fi
    print_status ".zshrc installed"
fi

# Starship prompt
if [[ -f "./Dots/.config/starship.toml" ]]; then
    install_config "Starship" "./Dots/.config/starship.toml" "$HOME/.config/starship.toml"
fi

# Pywal theming
if [[ -d "./Dots/.config/wal" ]]; then
    install_config "Pywal" "./Dots/.config/wal" "$HOME/.config/wal"
fi

# X11 configurations
if [[ -d "./Dots/.config/x11" ]]; then
    install_config "X11 config" "./Dots/.config/x11" "$HOME/.config/x11"
fi

# libinput-gestures config
if [[ -f "./Dots/.config/libinput-gestures.conf" ]]; then
    install_config "libinput-gestures" "./Dots/.config/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
fi

# xsettingsd config
if [[ -d "./Dots/.config/xsettingsd" ]]; then
    install_config "xsettingsd" "./Dots/.config/xsettingsd" "$HOME/.config/xsettingsd"
fi

# Install wallpapers
if [[ -d "./Dots/Wallpaper" ]]; then
    print_status "Installing wallpapers..."
    mkdir -p ~/Pictures/wallpapers
    if ! cp -r ./Dots/Wallpaper/* ~/Pictures/wallpapers/; then
        print_error "Failed to install wallpapers"
        exit 1
    fi
    print_status "Wallpapers installed"
fi

# Install custom fonts
if [[ -d "./Dots/.fonts" ]]; then
    print_status "Installing custom fonts..."
    mkdir -p ~/.local/share/fonts
    if ! cp -r ./Dots/.fonts/* ~/.local/share/fonts/; then
        print_error "Failed to install custom fonts"
        exit 1
    fi
    
    if ! fc-cache -fv; then
        print_warning "Font cache update failed, but fonts were copied"
    fi
    print_status "Custom fonts installed"
fi

# Install icons
if [[ -d "./Dots/.icons" ]]; then
    print_status "Installing icons..."
    mkdir -p ~/.local/share/icons
    if ! cp -r ./Dots/.icons/* ~/.local/share/icons/; then
        print_error "Failed to install icons"
        exit 1
    fi
    print_status "Icons installed"
fi

# Make scripts executable
if [[ -d "$HOME/.config/qtile/scripts" ]]; then
    print_status "Making qtile scripts executable..."
    if ! chmod +x ~/.config/qtile/scripts/*.sh 2>/dev/null; then
        print_warning "Some qtile scripts could not be made executable"
    fi
fi

if [[ -f "$HOME/.config/qtile/autostart_once.sh" ]]; then
    chmod +x ~/.config/qtile/autostart_once.sh
fi

# Set up X11 configuration for Qtile
print_status "Configuring X11 for Qtile..."

# Create or update .xinitrc
print_status "Setting up .xinitrc for Qtile..."
if [[ -f ~/.xinitrc ]]; then
    rm -f ~/.xinitrc
fi

# Create new .xinitrc with Qtile X11 configuration
if ! cat > ~/.xinitrc << 'EOF'; then
#!/bin/sh

# Merge in defaults and keymaps
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# Run all system xinitrc scripts
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Source X11 profile if it exists
if [ -f ~/.config/x11/xprofile ]; then
    . ~/.config/x11/xprofile
fi

# Start Qtile with X11 backend
exec qtile start -b x11
EOF
    print_error "Failed to create .xinitrc"
    exit 1
fi

if ! chmod +x ~/.xinitrc; then
    print_error "Failed to make .xinitrc executable"
    exit 1
fi

print_status ".xinitrc configured for Qtile X11"

# Set Zsh as default shell if not already
current_shell=$(basename "$SHELL")
if [[ "$current_shell" != "zsh" ]]; then
    if command -v zsh &> /dev/null && [[ -x "$(which zsh)" ]]; then
        print_status "Setting Zsh as default shell..."
        if ! chsh -s "$(which zsh)"; then
            print_warning "Failed to set zsh as default shell. You can change it manually later."
        fi
    else
        print_error "Zsh not found or not executable"
        exit 1
    fi
fi

# Enable services
print_status "Enabling system services..."
if ! sudo systemctl enable NetworkManager; then
    print_warning "Failed to enable NetworkManager"
fi

# Add user to necessary groups
print_status "Adding user to necessary groups..."
GROUPS_TO_ADD=("audio" "video" "storage" "optical" "lp" "scanner")
GROUPS_ADDED=()

for group in "${GROUPS_TO_ADD[@]}"; do
    if ! groups | grep -q "$group"; then
        if sudo usermod -a -G "$group" "$USER"; then
            GROUPS_ADDED+=("$group")
        else
            print_warning "Failed to add user to $group group"
        fi
    fi
done

if [[ ${#GROUPS_ADDED[@]} -gt 0 ]]; then
    print_status "Added user to groups: ${GROUPS_ADDED[*]}"
    print_warning "You'll need to log out and back in for group changes to take effect"
fi

# Disable SDDM since we're using startx
if systemctl is-enabled sddm &>/dev/null; then
    print_status "Disabling SDDM (using startx instead)..."
    if ! sudo systemctl disable sddm; then
        print_warning "Failed to disable SDDM"
    fi
fi

# Enable libinput-gestures for the user
if command -v libinput-gestures &> /dev/null; then
    print_status "Enabling libinput-gestures..."
    
    # Add user to input group if not already
    if ! groups | grep -q "input"; then
        print_status "Adding user to input group for libinput-gestures..."
        if ! sudo usermod -a -G input "$USER"; then
            print_warning "Failed to add user to input group"
        else
            print_warning "You'll need to log out and back in for input group changes to take effect"
        fi
    fi
    
    if ! libinput-gestures-setup autostart; then
        print_warning "Failed to enable libinput-gestures autostart"
    fi
fi

# NVIDIA specific setup
if [[ "$gpu_choice" = "1" ]]; then
    print_status "Configuring NVIDIA settings..."
    # Enable DRM kernel mode setting
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub 2>/dev/null; then
        print_warning "Consider adding 'nvidia-drm.modeset=1' to your kernel parameters"
        print_warning "Edit /etc/default/grub and add it to GRUB_CMDLINE_LINUX_DEFAULT"
        print_warning "Then run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
    fi
fi

# Final setup
print_status "Performing final setup..."

# Create necessary directories
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/bin
mkdir -p ~/Screenshots

# Set up pywal if wallpapers exist
if [[ -d ~/Pictures/wallpapers ]] && command -v wal &> /dev/null; then
    print_status "Generating initial color schemes with pywal..."
    first_wallpaper=$(find ~/Pictures/wallpapers -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" 2>/dev/null | head -n 1)
    if [[ -n "$first_wallpaper" ]]; then
        if ! wal -i "$first_wallpaper" -q; then
            print_warning "Failed to generate initial colorscheme with pywal"
        else
            print_status "Initial colorscheme generated"
        fi
    fi
fi

# Completion message
clear
print_header "╔══════════════════════════════════════╗"
print_header "║         Installation Complete!       ║"
print_header "╚══════════════════════════════════════╝"
echo
print_status "Ky-Suigetsu Qtile (X11) setup has been installed successfully!"
echo
print_status "What's been installed:"
echo "  • Qtile window manager (X11 only) with qtile-extras"
echo "  • Complete audio system (PipeWire)"
echo "  • Kitty terminal emulator"
echo "  • Essential utilities and applications"
echo "  • Custom fonts and configurations"
echo "  • Plank dock and all your selected configs"
echo "  • Configured .xinitrc for X11 startup"
echo
print_status "Configurations installed:"
echo "  • Qtile, Kitty, Rofi, Dunst, Picom"
echo "  • Plank, Ranger, Fastfetch, Flameshot, Bat"
echo "  • Zsh, Starship, Pywal, X11 configs"
echo "  • libinput-gestures, xsettingsd"
echo "  • Custom fonts, icons, and wallpapers"
echo
print_status "How to start Qtile:"
echo "  1. Reboot or logout completely"
echo "  2. Login to TTY (Ctrl+Alt+F2 if needed)"
echo "  3. Run: startx"
echo "  4. Qtile will start with X11 backend"
echo
print_status "Alternative startup method:"
echo "  • You can also run 'qtile start -b x11' directly"
echo "  • Or add 'startx' to your shell profile for auto-start"
echo
print_status "Configuration notes:"
echo "  • Qtile scripts are in ~/.config/qtile/scripts/"
echo "  • Repository available at ~/ky-suigetsu for future updates"
echo
if [[ "$gpu_choice" = "1" ]]; then
    print_warning "NVIDIA users: You may need to reboot for drivers to work properly"
fi
echo
read -p "Would you like to start Qtile now with startx? (y/N): " start_choice
if [[ $start_choice =~ ^[Yy]$ ]]; then
    print_status "Starting Qtile with X11..."
    startx
else
    print_status "You can start Qtile later by running: startx"
    print_status "Or directly with: qtile start -b x11"
fi