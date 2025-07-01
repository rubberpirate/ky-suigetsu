import json
from utils import dir

directory = f'{dir.get()}/config.json'
variables = {
    'bar': 'decorated',
    'colorscheme': 'catppuccin',
    'terminal': 'kitty',
    'wallpaper_main': '/home/rubberpirate/Wallpaper/wall2.png',
    'wallpaper_sec': '/home/rubberpirate/Wallpaper/wall2.png',
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
