#!/usr/bin/env python3
"""Mist niri config = niri's own default config with a few exact substitutions.
Fails loudly if a substitution no longer matches (e.g. after a niri update)."""
import os, re, sys
src = open(sys.argv[1]).read()

def sub(pattern, repl, flags=0):
    global src
    src, n = re.subn(pattern, repl, src, count=1, flags=flags)
    if n != 1:
        sys.exit(f"no match for: {pattern}")

sub(r'spawn-at-startup "waybar"',
    'spawn-at-startup "swaybg" "-c" "#DDE2E6"\n'
    'spawn-at-startup "sh" "-c" "mkdir -p ~/.cache/niri-mist && exec qs -p ~/.config/quickshell/mist > ~/.cache/niri-mist/qs.log 2>&1"')
sub(r'gaps 16', 'gaps 14')
sub(r'active-color "#7fc8ff"', 'active-color "#101418"')
sub(r'inactive-color "#505050"', 'inactive-color "#C6CFD6"')
sub(r'(focus-ring \{[^}]*?)(?<![/#])width 4', r'\1width 2')
sub(r'/-window-rule \{(\s*)geometry-corner-radius 12', r'window-rule {\1geometry-corner-radius 18')
sub(r'(\nhotkey-overlay \{)', r'\nprefer-no-csd\n\1')
sub(r'(hotkey-overlay \{)', r'\1\n    skip-at-startup')
sub(r'(\n    Mod\+D [^\n]*\n)', r'\1    Mod+X hotkey-overlay-title="Power menu" { spawn "mist-power"; }\n')
sub(r'spawn "alacritty"', 'spawn "ghostty"')
sub(r'alacritty', 'ghostty')
open(sys.argv[2], "w").write(src)
