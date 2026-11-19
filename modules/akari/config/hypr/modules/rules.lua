-- ============================================================================
-- Window, Workspace & Layer Rules (Strict M3 — Solid Surfaces, Zero Blur)
-- ============================================================================

-- Primary workspaces anchored comfortably across monitors
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", default = true, persistent = true })

-- Standard usability fixes
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Discord / Vesktop floating rule (preserved from user setup)
hl.window_rule({
    name   = "discord-floating",
    match  = { class = "^(vesktop|discord|com\\.discordapp\\.Discord)$" },
    float  = true,
    center = true,
    size   = "1120 780",
})

-- Media, utilities & audio mixers floating centered
hl.window_rule({
    name   = "utility-floating",
    match  = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|pavucontrol-qt|nm-connection-editor|org\\.gnome\\.Calculator|imv|mpv|fcitx5-config-qt)$" },
    float  = true,
    center = true,
    size   = "900 620",
})

-- File picker / portal dialogs
hl.window_rule({
    name   = "portal-dialogs",
    match  = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde)$" },
    float  = true,
    center = true,
    size   = "920 640",
})

-- Prevent any XWayland/fallback Fcitx5 candidate window from ever being tiled
hl.window_rule({
    name  = "fcitx-popup-guard",
    match = { class = "^(fcitx|fcitx5|org\\.fcitx\\..*)$" },
    float = true,
    no_focus = true,
    no_anim = true,
    pin = true,
})

hl.window_rule({
    name  = "fcitx-title-guard",
    match = { title = "^(Fcitx5 Input Window)$" },
    float = true,
    no_focus = true,
    no_anim = true,
    pin = true,
})

-- Picture-in-Picture
hl.window_rule({
    name  = "pip-floating",
    match = { title = "^(Picture-in-Picture|ピクチャーインピクチャー)$" },
    float = true,
    pin   = true,
})
