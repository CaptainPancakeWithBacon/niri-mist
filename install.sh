#!/bin/sh
# User-level install only: nothing here touches GNOME or needs sudo.
# Prints the one sudo line that adds the login-screen entry.
set -e
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.local/bin ~/.config/niri ~/.config/xdg-desktop-portal ~/.config/systemd/user

install -m755 "$here/src/niri/target/release/niri" ~/.local/bin/niri
install -m755 "$here/src/xwayland-satellite/target/release/xwayland-satellite" ~/.local/bin/
cmake --install "$here/src/quickshell/build" >/dev/null
install -m755 "$here/session/niri-mist-session" "$here/session/mist-power" ~/.local/bin/
install -m644 "$here/session/niri.service" "$here/session/niri-shutdown.target" ~/.config/systemd/user/

python3 "$here/niri/make-config.py" "$here/src/niri/resources/default-config.kdl" ~/.config/niri/config.kdl
niri validate || { echo "niri config invalid"; exit 1; }

link() { rm -rf "$2"; ln -s "$1" "$2"; }
mkdir -p ~/.config/quickshell
link "$here/quickshell"        ~/.config/quickshell/mist
link "$here/mako"              ~/.config/mako
link "$here/fuzzel"            ~/.config/fuzzel
link "$here/swaylock"          ~/.config/swaylock
cp "$here/src/niri/resources/niri-portals.conf" ~/.config/xdg-desktop-portal/niri-portals.conf

sed "s|@HOME@|$HOME|" "$here/session/niri-mist.desktop.in" > "$here/session/niri-mist.desktop"
echo "Done. To get the login entry, run:"
echo "  sudo install -m644 $here/session/niri-mist.desktop /usr/share/wayland-sessions/niri-mist.desktop"
