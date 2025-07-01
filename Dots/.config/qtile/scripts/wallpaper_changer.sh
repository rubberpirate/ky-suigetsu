#!/bin/sh
# =============================================================
# Author:  gh0stzk
# Repo:    https://github.com/gh0stzk/dotfiles
# Date:    27.06.2025 11:43:32

# WallSelect - Dynamic wallpaper selector with intelligent caching system
# Features:
#   ✔ Auto-updating menu (add/delete wallpapers without restart)
#   ✔ Parallel image processing (optimized CPU usage)
#   ✔ XXHash64 checksum verification for cache integrity
#   ✔ Orphaned cache detection and cleanup
#   ✔ Lockfile system for safe concurrent operations
#   ✔ Rofi integration with theme support
#   ✔ Lightweight (~2ms overhead on cache hits)
#
# Dependencies:
#   → Core: bspwm, xrandr, xdpyinfo, rofi, xxhsum (xxhash)
#   → Media: feh, imagemagick
#   → GNU: findutils, coreutils

# Copyright (C) 2021-2025 gh0stzk <z0mbi3.zk@protonmail.com>
# Licensed under GPL-3.0 license
# =============================================================

# Set some variables for Qtile
WALLPAPER_DIR="$HOME/Wallpaper"
QTILE_DIR="$HOME/.config/qtile"
QTILE_WORK_DIR="$HOME/Downloads/qtile"
CACHE_DIR="$HOME/.cache/wallpaper_qtile"
DEFAULT_BG="282738"

# Create cache dir if not exists
[ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR"

rofi_command="rofi -dmenu -theme $HOME/.config/rofi/WallSelect.rasi"

# Detect number of cores and set a sensible number of jobs
get_optimal_jobs() {
    cores=$(nproc)
    if [ "$cores" -le 2 ]; then
        echo 2
    elif [ "$cores" -gt 4 ]; then
        echo 4
    else
        echo $((cores - 1))
    fi
}

PARALLEL_JOBS=$(get_optimal_jobs)

process_func_def='process_image() {
    imagen="$1"
    nombre_archivo=$(basename "$imagen")
    cache_file="${CACHE_DIR}/${nombre_archivo}"
    md5_file="${CACHE_DIR}/.${nombre_archivo}.md5"
    lock_file="${CACHE_DIR}/.lock_${nombre_archivo}"
    
    # Use xxh64sum if available, fallback to md5sum
    if command -v xxh64sum >/dev/null 2>&1; then
        current_hash=$(xxh64sum "$imagen" | cut -d " " -f1)
    else
        current_hash=$(md5sum "$imagen" | cut -d " " -f1)
    fi
    
    (
        flock -x 9
        if [ ! -f "$cache_file" ] || [ ! -f "$md5_file" ] || [ "$current_hash" != "$(cat "$md5_file" 2>/dev/null)" ]; then
            if command -v magick >/dev/null 2>&1; then
                magick "$imagen" -resize 500x500^ -gravity center -extent 500x500 "$cache_file"
            elif command -v convert >/dev/null 2>&1; then
                convert "$imagen" -resize 500x500^ -gravity center -extent 500x500 "$cache_file"
            else
                cp "$imagen" "$cache_file"
            fi
            echo "$current_hash" > "$md5_file"
        fi
        rm -f "$lock_file"
    ) 9>"$lock_file"
}'

export process_func_def CACHE_DIR WALLPAPER_DIR

# Clean old locks before starting
rm -f "${CACHE_DIR}"/.lock_* 2>/dev/null || true

# Process files in parallel
find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 | \
    xargs -0 -P "$PARALLEL_JOBS" -I {} sh -c "$process_func_def; process_image \"{}\""

# Clean orphaned cache files and their locks
for cached in "$CACHE_DIR"/*; do
    [ -f "$cached" ] || continue
    original="${WALLPAPER_DIR}/$(basename "$cached")"
    if [ ! -f "$original" ]; then
        nombre_archivo=$(basename "$cached")
        rm -f "$cached" \
            "${CACHE_DIR}/.${nombre_archivo}.md5" \
            "${CACHE_DIR}/.lock_${nombre_archivo}"
    fi
done

# Clean any remaining lock files
rm -f "${CACHE_DIR}"/.lock_* 2>/dev/null || true

# Launch rofi
wall_selection=$(find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 |
    xargs -0 basename -a |
    LC_ALL=C sort |
    while IFS= read -r A; do
        printf '%s\000icon\037%s/%s\n' "$A" "$CACHE_DIR" "$A"
    done | $rofi_command)

# Apply wallpaper with pywal integration
if [ -n "$wall_selection" ]; then
    image_path="${WALLPAPER_DIR}/${wall_selection}"
    
    # Apply with pywal if available
    if command -v wal >/dev/null 2>&1; then
        wal -b "282738" -i "$image_path" -t
        
        # Update qtile configs if available
        for config_dir in "$QTILE_WORK_DIR" "$QTILE_DIR"; do
            if [ -f "$config_dir/config.json" ] && command -v jq >/dev/null 2>&1; then
                temp_file=$(mktemp)
                jq --arg wallpaper "$image_path" '.wallpaper_main = $wallpaper | .wallpaper_sec = $wallpaper' "$config_dir/config.json" > "$temp_file"
                mv "$temp_file" "$config_dir/config.json"
            fi
        done
        
        # Restart qtile
        qtile cmd-obj -o cmd -f restart 2>/dev/null || true
        
        notify-send "Wallpaper" "Applied $(basename "$image_path") with pywal" -i image-x-generic || true
    else
        # Fallback to feh
        feh --no-fehbg --bg-fill "$image_path"
        notify-send "Wallpaper" "Applied $(basename "$image_path")" -i image-x-generic || true
    fi
fi
