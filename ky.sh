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

# System update 
print_status "Performing full system update..."
sudo pacman --noconfirm -Syu
print_status "System update completed"
sleep 2

# Install Git if not present 
print_status "Ensuring git is installed..."
sudo pacman -S --noconfirm --needed git
sleep 1

# Install/Check Yay AUR helper
print_status "Checking for yay AUR helper..."
if ! command -v yay &> /dev/null; then
    print_status "Installing yay AUR helper..."
    mkdir -p ~/.srcs
    git clone https://aur.archlinux.org/yay.git ~/.srcs/yay
    (cd ~/.srcs/yay && makepkg -si --noconfirm)
    print_status "Yay installed successfully"
else
    print_status "Yay already installed"
fi
sleep 1

# Clone the dotfiles repository
print_status "Cloning Ky-Suigetsu dotfiles repository..."
if [ -d ~/ky-suigetsu ]; then
    print_status "Repository already exists, updating..."
    (cd ~/ky-suigetsu && git pull)
else
    git clone https://github.com/rubberpirate/ky-suigetsu.git ~/ky-suigetsu
fi
print_status "Repository cloned/updated successfully"

# Change to the repository directory
cd ~/ky-suigetsu

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
        GPU_DRIVERS="nvidia-dkms nvidia-utils nvidia-settings linux-headers"
        ;;
    2)
        print_status "Installing AMD drivers..."
        GPU_DRIVERS="xf86-video-amdgpu"
        ;;
    3)
        print_status "Installing Intel drivers..."
        GPU_DRIVERS="xf86-video-intel"
        ;;
    *)
        print_status "Skipping GPU driver installation"
        GPU_DRIVERS=""
        ;;
esac

# Install base packages
print_status "Installing core system packages..."
sudo pacman -S --noconfirm --needed \
    base-devel \
    xorg-server \
    xorg-xinit \
    xorg-xbacklight \
    xorg-xsetroot \
    $GPU_DRIVERS

# Install window manager and core utilities (X11 only)
print_status "Installing Qtile (X11) and core utilities..."
yay -S --noconfirm --needed \
    qtile \
    qtile-extras \
    python-psutil \
    python-dbus-next \
    python-iwlib \
    python-pulsectl-asyncio \
    python-plyer

# Install terminal and shell
print_status "Installing terminal and shell..."
yay -S --noconfirm --needed \
    kitty \
    zsh \
    starship

# Install audio system
print_status "Installing audio system..."
yay -S --noconfirm --needed \
    pipewire \
    pipewire-alsa \
    pipewire-jack \
    pipewire-pulse \
    wireplumber \
    pavucontrol \
    pulsemixer \
    brightnessctl

# Install compositor and effects
print_status "Installing compositor and visual effects..."
yay -S --noconfirm --needed \
    picom \
    dunst \
    rofi \
    nitrogen \
    feh \
    flameshot

# Install media and utilities
print_status "Installing media players and utilities..."
yay -S --noconfirm --needed \
    ranger \
    htop \
    fastfetch \
    neovim \
    bat

# Install plank dock
print_status "Installing Plank dock..."
yay -S --noconfirm --needed plank

# Install pywal for theming
print_status "Installing pywal..."
yay -S --noconfirm --needed python-pywal

# Install libinput-gestures
print_status "Installing libinput-gestures..."
yay -S --noconfirm --needed libinput-gestures

# Install xsettingsd
print_status "Installing xsettingsd..."
yay -S --noconfirm --needed xsettingsd

# Install fonts
print_status "Installing fonts..."
yay -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    ttf-nerd-fonts-symbols-mono \
    otf-hasklig-nerd \
    ttf-material-design-icons-extended \
    ttf-noto-sans-mono-vf

# Backup and configuration installation functions
backup_and_install() {
    local config_name="$1"
    local source_path="$2"
    local target_path="$3"

    if [ -d "$target_path" ] || [ -f "$target_path" ]; then
        print_status "Backing up existing $config_name configuration..."
        mkdir -p ~/.config-backup
        if [ -d "$target_path" ]; then
            cp -r "$target_path" ~/.config-backup/$(basename "$target_path")-$(date +%Y%m%d-%H%M%S)
        else
            cp "$target_path" ~/.config-backup/$(basename "$target_path")-$(date +%Y%m%d-%H%M%S)
        fi
        rm -rf "$target_path"
    fi
    
    mkdir -p "$(dirname "$target_path")"
    cp -r "$source_path" "$target_path"
    print_status "$config_name configuration installed"
}

# Install configurations from Dots directory
print_status "Installing configuration files..."

# Main qtile config
if [ -d "./Dots/.config/qtile" ]; then
    backup_and_install "Qtile" "./Dots/.config/qtile" "$HOME/.config/qtile"
fi

# Kitty terminal
if [ -d "./Dots/.config/kitty" ]; then
    backup_and_install "Kitty" "./Dots/.config/kitty" "$HOME/.config/kitty"
fi

# Rofi launcher
if [ -d "./Dots/.config/rofi" ]; then
    backup_and_install "Rofi" "./Dots/.config/rofi" "$HOME/.config/rofi"
fi

# Dunst notifications
if [ -d "./Dots/.config/dunst" ]; then
    backup_and_install "Dunst" "./Dots/.config/dunst" "$HOME/.config/dunst"
fi

# Picom compositor
if [ -d "./Dots/.config/picom" ]; then
    backup_and_install "Picom" "./Dots/.config/picom" "$HOME/.config/picom"
fi

# Plank dock
if [ -d "./Dots/.config/plank" ]; then
    backup_and_install "Plank" "./Dots/.config/plank" "$HOME/.config/plank"
fi

# Ranger file manager
if [ -d "./Dots/.config/ranger" ]; then
    backup_and_install "Ranger" "./Dots/.config/ranger" "$HOME/.config/ranger"
fi

# Fastfetch system info
if [ -d "./Dots/.config/fastfetch" ]; then
    backup_and_install "Fastfetch" "./Dots/.config/fastfetch" "$HOME/.config/fastfetch"
fi

# Flameshot screenshots
if [ -d "./Dots/.config/flameshot" ]; then
    backup_and_install "Flameshot" "./Dots/.config/flameshot" "$HOME/.config/flameshot"
fi

# Bat syntax highlighter
if [ -d "./Dots/.config/bat" ]; then
    backup_and_install "Bat" "./Dots/.config/bat" "$HOME/.config/bat"
fi

# Zsh shell config
if [ -d "./Dots/.config/zsh" ]; then
    backup_and_install "Zsh config" "./Dots/.config/zsh" "$HOME/.config/zsh"
fi

# Copy .zshrc to home directory
if [ -f "./Dots/.zshrc" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        print_status "Backing up existing .zshrc..."
        mkdir -p ~/.config-backup
        cp "$HOME/.zshrc" ~/.config-backup/.zshrc-$(date +%Y%m%d-%H%M%S)
    fi
    cp "./Dots/.zshrc" "$HOME/.zshrc"
    print_status ".zshrc installed"
fi

# Starship prompt
if [ -f "./Dots/.config/starship.toml" ]; then
    backup_and_install "Starship" "./Dots/.config/starship.toml" "$HOME/.config/starship.toml"
fi

# Pywal theming
if [ -d "./Dots/.config/wal" ]; then
    backup_and_install "Pywal" "./Dots/.config/wal" "$HOME/.config/wal"
fi

# X11 configurations
if [ -d "./Dots/.config/x11" ]; then
    backup_and_install "X11 config" "./Dots/.config/x11" "$HOME/.config/x11"
fi

# libinput-gestures config
if [ -f "./Dots/.config/libinput-gestures.conf" ]; then
    backup_and_install "libinput-gestures" "./Dots/.config/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
fi

# xsettingsd config
if [ -d "./Dots/.config/xsettingsd" ]; then
    backup_and_install "xsettingsd" "./Dots/.config/xsettingsd" "$HOME/.config/xsettingsd"
fi

# Install wallpapers
if [ -d "./Dots/Wallpaper" ]; then
    print_status "Installing wallpapers..."
    mkdir -p ~/Pictures/wallpapers
    cp -r ./Dots/Wallpaper/* ~/Pictures/wallpapers/
    print_status "Wallpapers installed"
fi

# Install custom fonts
if [ -d "./Dots/.fonts" ]; then
    print_status "Installing custom fonts..."
    mkdir -p ~/.local/share/fonts
    cp -r ./Dots/.fonts/* ~/.local/share/fonts/
    fc-cache -fv
    print_status "Custom fonts installed"
fi

# Install icons
if [ -d "./Dots/.icons" ]; then
    print_status "Installing icons..."
    mkdir -p ~/.local/share/icons
    cp -r ./Dots/.icons/* ~/.local/share/icons/
    print_status "Icons installed"
fi

# Make scripts executable
if [ -d "$HOME/.config/qtile/scripts" ]; then
    print_status "Making qtile scripts executable..."
    chmod +x ~/.config/qtile/scripts/*.sh
fi

if [ -f "$HOME/.config/qtile/autostart_once.sh" ]; then
    chmod +x ~/.config/qtile/autostart_once.sh
fi

# Set up X11 configuration for Qtile
print_status "Configuring X11 for Qtile..."

# Create or update .xinitrc
print_status "Setting up .xinitrc for Qtile..."
if [ -f ~/.xinitrc ]; then
    print_status "Backing up existing .xinitrc..."
    mkdir -p ~/.config-backup
    cp ~/.xinitrc ~/.config-backup/.xinitrc-$(date +%Y%m%d-%H%M%S)
fi

# Create new .xinitrc with Qtile X11 configuration
cat > ~/.xinitrc << 'EOF'
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

chmod +x ~/.xinitrc
print_status ".xinitrc configured for Qtile X11"

# Set Zsh as default shell if not already
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
    print_status "Setting Zsh as default shell..."
    chsh -s $(which zsh)
fi

# Enable services
print_status "Enabling system services..."
sudo systemctl enable NetworkManager

# Disable SDDM since we're using startx
if systemctl is-enabled sddm &>/dev/null; then
    print_status "Disabling SDDM (using startx instead)..."
    sudo systemctl disable sddm
fi

# Enable libinput-gestures for the user
if command -v libinput-gestures &> /dev/null; then
    print_status "Enabling libinput-gestures..."
    libinput-gestures-setup autostart
fi

# NVIDIA specific setup
if [ "$gpu_choice" = "1" ]; then
    print_status "Configuring NVIDIA settings..."
    # Enable DRM kernel mode setting
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        print_warning "Consider adding 'nvidia-drm.modeset=1' to your kernel parameters"
        print_warning "Edit /etc/default/grub and add it to GRUB_CMDLINE_LINUX_DEFAULT"
    fi
fi

# Final setup
print_status "Performing final setup..."

# Create necessary directories
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/bin
mkdir -p ~/Screenshots

# Set up pywal if wallpapers exist
if [ -d ~/Pictures/wallpapers ] && command -v wal &> /dev/null; then
    print_status "Generating initial color schemes with pywal..."
    first_wallpaper=$(find ~/Pictures/wallpapers -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" 2>/dev/null | head -n 1)
    if [ -n "$first_wallpaper" ]; then
        wal -i "$first_wallpaper" -q
        print_status "Initial colorscheme generated"
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
echo "  • Your original configs are backed up in ~/.config-backup"
echo "  • Qtile scripts are in ~/.config/qtile/scripts/"
echo "  • Repository cloned to ~/ky-suigetsu for future updates"
echo
if [ "$gpu_choice" = "1" ]; then
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