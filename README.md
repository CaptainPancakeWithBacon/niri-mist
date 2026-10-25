# niri-mist

A second login session next to GNOME: niri (scrollable tiling) with a Quickshell strip in the
Mist design (fog, ink, slate). Nothing here touches the GNOME session.

- `quickshell/`: the strip (`shell.qml`) and the quick-settings card (`QuickSettings.qml`)
- `niri/make-config.py`: builds `~/.config/niri/config.kdl` from niri's own default config
- `mako/`, `fuzzel/`, `swaylock/`: notifications, launcher, lock screen in the same palette
- `session/`: login wrapper (runs niri as `niri.service`, needed for the portals), systemd units, power menu
- `install.sh`: user-level install; prints the one sudo line for the login entry

Build (sources go in `src/`, ignored): niri v26.04 and xwayland-satellite v0.8.3 with `cargo build --release`,
Quickshell 0.3.2 with `cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release -DCRASH_HANDLER=OFF`.
Clone niri with the git-lfs filter disabled (its LFS files are screenshots).

Keys: Super+T terminal, Super+D launcher, Super+X power menu, Super+Shift+E quit, Super+Alt+L lock.
Quickshell logs to `~/.cache/niri-mist/qs.log`.
