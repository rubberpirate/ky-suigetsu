# Debug script to test your Qtile widget configuration
# Save this as debug_qtile.py and run it to check for issues

import sys
import os

# Add your qtile config path if needed
sys.path.append(os.path.expanduser('~/.config/qtile'))

def debug_imports():
    """Test if all imports work correctly"""
    print("=== Testing Imports ===")
    try:
        from qtile_extras import widget
        print("✓ qtile_extras.widget imported successfully")
    except ImportError as e:
        print(f"✗ qtile_extras import failed: {e}")
        return False
    
    try:
        from utils import color, config
        print("✓ utils imported successfully")
        print(f"  config keys: {list(config.keys()) if isinstance(config, dict) else 'config is not a dict'}")
        print(f"  with_battery: {config.get('with_battery', 'NOT SET')}")
        print(f"  with_wlan: {config.get('with_wlan', 'NOT SET')}")
    except ImportError as e:
        print(f"✗ utils import failed: {e}")
        return False
    
    try:
        import core.widgets
        print("✓ core.widgets imported successfully")
    except ImportError as e:
        print(f"✗ core.widgets import failed: {e}")
        return False
    
    return True

def debug_network_interfaces():
    """Check available network interfaces"""
    print("\n=== Network Interfaces ===")
    try:
        import psutil
        interfaces = psutil.net_if_addrs()
        wireless_interfaces = [iface for iface in interfaces.keys() 
                             if any(x in iface.lower() for x in ['wl', 'wifi', 'wireless'])]
        print(f"All interfaces: {list(interfaces.keys())}")
        print(f"Wireless interfaces: {wireless_interfaces}")
    except ImportError:
        print("psutil not available, checking with os commands...")
        os.system("ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' '")

def debug_battery():
    """Check if battery is available"""
    print("\n=== Battery Status ===")
    try:
        import psutil
        battery = psutil.sensors_battery()
        if battery:
            print(f"✓ Battery detected: {battery.percent}% ({'charging' if battery.power_plugged else 'discharging'})")
        else:
            print("✗ No battery detected")
    except ImportError:
        print("psutil not available, checking /sys/class/power_supply/")
        if os.path.exists('/sys/class/power_supply/'):
            batteries = [d for d in os.listdir('/sys/class/power_supply/') if 'BAT' in d]
            print(f"Battery directories: {batteries}")
        else:
            print("No battery directory found")

def debug_widget_creation():
    """Test creating widgets individually"""
    print("\n=== Testing Widget Creation ===")
    
    # Test basic widget creation
    try:
        from qtile_extras import widget
        test_widget = widget.TextBox(text="test")
        print("✓ Basic widget creation works")
    except Exception as e:
        print(f"✗ Basic widget creation failed: {e}")
        return False
    
    # Test battery widget
    try:
        battery = widget.Battery(format='{percent:2.0%}')
        print("✓ Battery widget creation works")
    except Exception as e:
        print(f"✗ Battery widget creation failed: {e}")
    
    # Test WiFi widget
    try:
        wlan = widget.Wlan(interface='wlan0')
        print("✓ WiFi widget creation works")
    except Exception as e:
        print(f"✗ WiFi widget creation failed: {e}")
    
    return True

def create_minimal_bar():
    """Create a minimal bar configuration for testing"""
    print("\n=== Creating Minimal Bar ===")
    try:
        from libqtile import bar
        from qtile_extras import widget
        
        minimal_widgets = [
            widget.TextBox(text="Test", foreground="#ffffff"),
            widget.Spacer(),
            widget.Battery(format='🔋 {percent:2.0%}', foreground="#ffffff"),
            widget.Wlan(format='📶 {percent:2.0%}', interface='wlan0', foreground="#ffffff"),
            widget.Volume(foreground="#ffffff"),
        ]
        
        test_bar = bar.Bar(minimal_widgets, 30)
        print("✓ Minimal bar created successfully")
        return True
    except Exception as e:
        print(f"✗ Minimal bar creation failed: {e}")
        return False

if __name__ == "__main__":
    print("Qtile Widget Debug Script")
    print("=" * 40)
    
    if not debug_imports():
        print("\n❌ Import issues found. Fix imports before proceeding.")
        sys.exit(1)
    
    debug_network_interfaces()
    debug_battery()
    
    if not debug_widget_creation():
        print("\n❌ Widget creation issues found.")
        sys.exit(1)
    
    if create_minimal_bar():
        print("\n✅ All tests passed! The issue might be in your bar configuration logic.")
    else:
        print("\n❌ Bar creation failed.")
