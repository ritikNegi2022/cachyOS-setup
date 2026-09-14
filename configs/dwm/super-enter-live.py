#!/usr/bin/env python3
# super-enter-live.py — temporary live fix for Super+Enter -> terminal
# Runs via pynput, spawns alacritty on Super+Enter (both plain and Shift)
# This is a fallback until dwm is rebuilt with config.h:90 fixed.
# Installed to ~/.local/bin/super-enter-live.py, started by dwm-session or manually.
import sys, subprocess, threading
try:
    from pynput import keyboard
except Exception as e:
    print(f"pynput not available: {e}", file=sys.stderr)
    sys.exit(1)

# Track modifiers
pressed = set()
last_spawn = 0

def spawn_term():
    global last_spawn
    import time
    now = time.time()
    if now - last_spawn < 0.3:
        return
    last_spawn = now
    try:
        subprocess.Popen(["alacritty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"spawn failed: {e}", file=sys.stderr)

def spawn_fullscreen():
    global last_spawn
    import time
    now = time.time()
    if now - last_spawn < 0.3:
        return
    last_spawn = now
    try:
        # Try wmctrl fullscreen toggle, fallback to xdotool
        subprocess.run(["wmctrl", "-r", ":ACTIVE:", "-b", "toggle,fullscreen"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except: 
        try:
            win = subprocess.check_output(["xdotool", "getactivewindow"], text=True).strip()
            subprocess.run(["xdotool", "windowstate", "--toggle", "FULLSCREEN", win], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except: pass

def spawn_group():
    global last_spawn
    import time
    now = time.time()
    if now - last_spawn < 0.3:
        return
    last_spawn = now
    try:
        # Hyprland-like group: toggle monocle (tabbed) vs tile
        subprocess.run(["xdotool", "key", "super+m"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except: pass

def on_press(key):
    try:
        # pynput Key.cmd is Super
        if key in (keyboard.Key.cmd, keyboard.Key.cmd_l, keyboard.Key.cmd_r):
            pressed.add("cmd")
        if key == keyboard.Key.shift or key == keyboard.Key.shift_l or key == keyboard.Key.shift_r:
            pressed.add("shift")
        if key == keyboard.Key.ctrl or key == keyboard.Key.ctrl_l or key == keyboard.Key.ctrl_r:
            pressed.add("ctrl")
        # char keys: f for fullscreen, y for group
        kchar = None
        try:
            if hasattr(key, 'char') and key.char:
                kchar = key.char.lower()
        except: pass
        if kchar == 'f' and "cmd" in pressed and "shift" not in pressed and "ctrl" not in pressed:
            # Super+f -> fullscreen (until dwm rebuild provides togglefullscreen)
            threading.Thread(target=spawn_fullscreen, daemon=True).start()
        elif kchar == 'y' and "cmd" in pressed:
            threading.Thread(target=spawn_group, daemon=True).start()
        elif key == keyboard.Key.enter:
            # Check if Super is held
            if "cmd" in pressed:
                # Spawn terminal for both Super+Enter and Super+Shift+Enter
                threading.Thread(target=spawn_term, daemon=True).start()
    except: pass

def on_release(key):
    try:
        if key in (keyboard.Key.cmd, keyboard.Key.cmd_l, keyboard.Key.cmd_r):
            pressed.discard("cmd")
        if key in (keyboard.Key.shift, keyboard.Key.shift_l, keyboard.Key.shift_r):
            pressed.discard("shift")
        if key in (keyboard.Key.ctrl, keyboard.Key.ctrl_l, keyboard.Key.ctrl_r):
            pressed.discard("ctrl")
    except: pass

print("super-enter-live: listening for Super+Enter -> alacritty (fallback until dwm rebuild)", flush=True)
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
