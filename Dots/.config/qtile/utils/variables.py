import json
from utils import dir

directory = f'{dir.get()}/config.json'
variables = {
    'bar': 'decorated',
    'colorscheme': 'catppuccin',
    'terminal': 'kitty',
    'wallpaper_main': '~/.config/qtile/wallpapers/sl.png',
    'wallpaper_sec': '~/.config/qtile/wallpapers/sl.png',
    'with_battery': True,
    'with_wlan': True,
    'two_monitors': False,
}

try:
    with open(directory, 'r') as file:
        config = json.load(file)
        file.close()
except FileNotFoundError:
    print("Config file not found. Using default config")
    with open(directory, 'w') as file:
        file.write(json.dumps(variables, indent = 2))
        config = variables.copy()
        file.close()
