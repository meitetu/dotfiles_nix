-- ============================================================================
-- Session Autostart
-- ============================================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Polkit authentication agent
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Wallpaper daemon + restore active wallpaper
    hl.exec_cmd("$HOME/.local/bin/akari-wallpaper --restore")

    -- Input method (Fcitx5 + Mozc)
    hl.exec_cmd("fcitx5 -d --replace")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- System tray applets & idle daemon
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hypridle")

    -- Akari Quickshell Desktop Shell (Bar, IME/Audio/Brightness OSD, Notifications, Control Center)
    hl.exec_cmd("$HOME/.local/bin/akari-ctl shell-start")
end)
