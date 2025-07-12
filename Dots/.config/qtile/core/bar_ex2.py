"""Ex2 Bar Configuration for Qtile - Catppuccin Theme"""

from libqtile import bar, qtile
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration
from utils import color, config, dir
import os

home = os.path.expanduser('~')
qtile_dir = dir.get()

# Ex2 color theme (catppuccin palette)
ex2_colors = {
    'accent': '#89b4fa',      # Blue
    'secondary': '#a6e3a1',   # Green  
    'tertiary': '#f9e2af',    # Yellow
    'quaternary': '#f38ba8',  # Pink/Red
    'quinary': '#cba6f7',     # Purple
    'senary': '#fab387',      # Peach
}

# Decoration functions (matching default bar style exactly)
def _left_decor(color_key: str, padding_x=None, padding_y=4, round=False):
    radius = 4 if round else [4, 0, 0, 4]
    color_value = ex2_colors.get(color_key, color.get(color_key, ex2_colors['accent']))
    return [
        RectDecoration(
            colour=color_value,
            radius=radius,
            filled=True,
            padding_x=padding_x,
            padding_y=padding_y,
        )
    ]

def _right_decor(round=False):
    radius = 4 if round else [0, 4, 4, 0]
    return [
        RectDecoration(
            colour=color['darkgray'],
            radius=radius,
            filled=True,
            padding_y=4,
            padding_x=0,
        )
    ]

# Separator functions (matching default)
def separator():
    return widget.Sep(
        foreground=color['bg'],
        padding=4,
        linewidth=3,
    )

def separator_sm():
    return widget.Sep(
        foreground=color['bg'],
        padding=1,
        linewidth=1,
        size_percent=55,
    )

# Callback functions (same as default)
def open_launcher():
    qtile.cmd_spawn('rofi -show drun -theme ~/.config/rofi/launcher.rasi')

def open_powermenu():
    qtile.cmd_spawn(f'{home}/.local/bin/power')

def open_wallpaper_menu():
    qtile.cmd_spawn(f'{qtile_dir}/scripts/wallpaper_changer.sh')

def create_ex2_bar():
    """Create EX2 bar that matches the default bar structure exactly"""
    
    return bar.Bar(
        [
            # System launcher (matches w_sys_icon)
            widget.TextBox(
                text='󰨈',
                font='Font Awesome 6 Free Solid',
                fontsize=22,
                foreground='#000000',
                background=ex2_colors['accent'],
                padding=16,
                mouse_callbacks={'Button1': open_launcher},
            ),
            
            # Group box (matches gen_groupbox)
            widget.GroupBox(
                font='Xiaolai SC',
                active=color['fg'],
                block_highlight_text_color=color['fg'],
                this_current_screen_border=color['fg'],
                this_screen_border=color['fg'],
                urgent_border=color['red'],
                background=color['bg'],
                other_current_screen_border=color['bg'],
                other_screen_border=color['bg'],
                highlight_color=color['darkgray'],
                inactive=color['gray'],
                foreground=color['white'],
                borderwidth=2,
                disable_drag=True,
                fontsize=20,
                highlight_method='line',
                padding_x=10,
                padding_y=16,
                rounded=False,
            ),
            
            separator(),
            
            # Spacer
            widget.Spacer(),
            
            # Window name
            widget.TextBox(
                text=' ',
                foreground='#ffffff',
                font='Font Awesome 6 Free Solid',
            ),
            widget.WindowName(
                foreground='#ffffff',
                width=bar.CALCULATED,
                empty_group_string='Desktop',
                max_chars=40,
            ),
            
            # Spacer
            widget.Spacer(),
            
            # Current layout (matches gen_current_layout)
            widget.CurrentLayoutIcon(
                custom_icon_paths=[os.path.expanduser('~/.config/qtile/icons')],
                scale=0.65,
                use_mask=True,
                foreground=color['bg'],
                decorations=_left_decor('secondary'),
            ),
            separator_sm(),
            widget.CurrentLayout(
                foreground=ex2_colors['secondary'],
                padding=8,
                decorations=_right_decor(),
            ),
            separator(),
            
            # Battery (matching w_battery from widgets.py)
            widget.Battery(
                format='{char}',
                charge_char='󰂄',
                discharge_char='󰁾',
                full_char='󰁹',
                unknown_char='',
                empty_char='',
                show_short_text=False,
                foreground=color['dark'],
                fontsize=18,
                padding=8,
                update_interval=3,
                decorations=_left_decor('senary'),
            ),
            separator_sm(),
            widget.Battery(
                format='{percent:2.0%}',
                show_short_text=False,
                foreground=ex2_colors['senary'],
                padding=8,
                update_interval=3,
                decorations=_right_decor(),
            ),
            separator(),
            
            # Volume icon
            widget.TextBox(
                text=' ',
                foreground=color['dark'],
                font='JetBrainsMono Nerd Font',
                fontsize=20,
                padding=8,
                decorations=_left_decor('tertiary'),
            ),
            separator_sm(),
            
            # Volume
            widget.PulseVolume(
                foreground=ex2_colors['tertiary'],
                limit_max_volume='True',
                padding=8,
                decorations=_right_decor(),
            ),
            separator(),
            
            # Network (matching w_wlan from widgets.py)
            widget.GenPollText(
                func=lambda: os.popen(f'{qtile_dir}/scripts/network_manager.sh icon').read().strip(),
                update_interval=3,
                foreground=color['dark'],
                fontsize=18,
                padding=8,
                decorations=_left_decor('quinary'),
                mouse_callbacks={
                    'Button1': lambda: qtile.cmd_spawn(f'{qtile_dir}/scripts/network_manager.sh menu'),
                    'Button3': lambda: qtile.cmd_spawn(f'{qtile_dir}/scripts/network_manager.sh simple-menu'),
                },
            ),
            separator_sm(),
            widget.GenPollText(
                func=lambda: os.popen(f'{qtile_dir}/scripts/network_manager.sh info').read().strip(),
                update_interval=3,
                foreground=ex2_colors['quinary'],
                padding=8,
                decorations=_right_decor(),
                mouse_callbacks={
                    'Button1': lambda: qtile.cmd_spawn(f'{qtile_dir}/scripts/network_manager.sh menu'),
                    'Button3': lambda: qtile.cmd_spawn(f'{qtile_dir}/scripts/network_manager.sh simple-menu'),
                },
            ),
            separator(),
            
            # Clock
            widget.TextBox(
                text='',
                font='JetBrainsMono Nerd Font',
                fontsize=16,
                foreground=color['dark'],
                padding=8,
                decorations=_left_decor('accent'),
                mouse_callbacks={'Button1': open_wallpaper_menu},
            ),
            separator_sm(),
            widget.Clock(
                format='%b %d, %H:%M',
                foreground=ex2_colors['accent'],
                padding=8,
                decorations=_right_decor(),
                mouse_callbacks={'Button1': open_wallpaper_menu},
            ),
            separator(),
            
            # Power menu
            widget.TextBox(
                text='⏻',
                background=ex2_colors['quaternary'],
                foreground='#000000',
                font='Font Awesome 6 Free Solid',
                fontsize=18,
                padding=16,
                mouse_callbacks={'Button1': open_powermenu},
            ),
        ],
        30,
        margin=[4, 6, 2, 6],
        border_width=[0, 0, 0, 0],
        border_color=color["fg"],
        background=color['bg'],
    )
