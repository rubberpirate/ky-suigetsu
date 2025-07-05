from qtile_extras import widget
from core.widgets import *
from utils import color, config
import subprocess

extra_bar = config["two_monitors"]

# Detect VirtualBox for compatibility adjustments
def is_virtualbox():
    try:
        result = subprocess.run(['systemd-detect-virt'], capture_output=True, text=True)
        return result.stdout.strip() == 'oracle'
    except:
        return False

# Adjust settings for VirtualBox compatibility
if is_virtualbox():
    # Use solid colors in VirtualBox
    bg_color = color["bg"]
    opacity = 1.0
else:
    bg_color = color["bg"]
    opacity = 0.8

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=15,
    padding=2,
    background=bg_color,
)
extension_defaults = widget_defaults.copy()

def create_bar(extra_bar=False):
    """Create top bar, defined as function to allow duplication in other monitors"""
    return bar.Bar(
        [
            w_sys_icon,
            *gen_groupbox(),
            separator(),
            gen_spacer(),
            *window_name(),
            gen_spacer(),
            *((w_systray,) if not extra_bar else ()),
            separator(),
            *gen_current_layout(),
            *w_battery,
            w_volume_icon,
            separator_sm(),
            w_volume,
            separator(),
            *w_wlan,
            *gen_clock(),
            w_power,
        ],
        30,
        margin=[4, 6, 2, 6],
        border_width=[0, 0, 0, 0],
        border_color=color["fg"],
        background=bg_color,  # Ensure solid background
        opacity=opacity if not is_virtualbox() else 1.0,  # Force opacity to 1.0 in VirtualBox
    )


main_screen_bar = create_bar()
secondary_screen_bar = bar.Gap(2)
if extra_bar:
    secondary_screen_bar = create_bar(extra_bar=True)
