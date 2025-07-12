from libqtile import bar
from libqtile.config import Screen
import os

from utils import config
from core.bar import main_screen_bar, secondary_screen_bar

# Check which bar configuration to use
def get_current_bar():
    bar_file = os.path.expanduser("~/.config/qtile/current_bar")
    if os.path.exists(bar_file):
        with open(bar_file, 'r') as f:
            bar_type = f.read().strip()
        
        if bar_type == "ex1":
            from core.bar_ex1 import create_ex1_bar
            return create_ex1_bar()
        elif bar_type == "ex2":
            from core.bar_ex2 import create_ex2_bar
            return create_ex2_bar()
    
    # Default bar
    return main_screen_bar

screens = [
    Screen(
        wallpaper=config['wallpaper_main'],
        wallpaper_mode="fill",
        top=get_current_bar(),
        bottom=bar.Gap(2),
        left=bar.Gap(2),
        right=bar.Gap(2),
    ),
]

if config['two_monitors']:
    screens.append(
        Screen(
            wallpaper=config['wallpaper_sec'],
            wallpaper_mode="fill",
            top=secondary_screen_bar,
            bottom=bar.Gap(2),
            left=bar.Gap(2),
            right=bar.Gap(2),
        ),
    )
