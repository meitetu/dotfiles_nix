-- ============================================================================
-- Material 3 Window Theme — Akari Hoshizaki (#FF4D79 · HCT scheme-fidelity)
-- Strictly Tonal Elevation & Solid M3 Borders (No Gradient, Blur, Glow, Shadow)
-- ============================================================================

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,
        border_size = 2,

        col = {
            active_border         = "rgba(ff4e7aff)", -- primary-container (#FF4E7A)
            inactive_border       = "rgba(5a4043ff)", -- outline-variant (#5A4043)
            nogroup_border        = "rgba(5a4043ff)",
            nogroup_border_active = "rgba(ff4e7aff)",
        },

        resize_on_border = true,
        extend_border_grab_area = 12,
        hover_icon_on_border = true,
        allow_tearing = false,
        layout = "dwindle",

        snap = {
            enabled = true,
            window_gap = 8,
            monitor_gap = 12,
            border_overlap = false,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding = 12,        -- M3 shape/md (12dp)
        rounding_power = 2.0, -- True circular M3 corner radius

        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,

        dim_special = 0.24,

        shadow = {
            enabled = false,
        },

        glow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    group = {
        insert_after_current = true,
        focus_removed_window = true,
        col = {
            border_active          = "rgba(ff4e7aff)",
            border_inactive        = "rgba(5a4043ff)",
            border_locked_active   = "rgba(ffb2bdff)",
            border_locked_inactive = "rgba(5a4043ff)",
        },
        groupbar = {
            enabled = true,
            font_family = "JetBrains Mono",
            font_size = 12,
            font_weight_active = "medium",
            font_weight_inactive = "normal",
            gradients = false,
            height = 24,
            indicator_height = 2,
            rounding = 4,
            rounding_power = 2.0,
            text_color = "rgba(f8dcdeff)",
            col = {
                active          = "rgba(7f273bff)", -- secondary-container
                inactive        = "rgba(26181aff)", -- surface-container-low
                locked_active   = "rgba(ff4e7aff)",
                locked_inactive = "rgba(26181aff)",
            },
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = "0xff1d0f12", -- surface-dim (#1D0F12)
        force_default_wallpaper = 0,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
})

-- Clean M3 Standard Deceleration Transitions
hl.curve("m3StandardDecel", { type = "bezier", points = { { 0.0, 0.0 }, { 0.0, 1.0 } } })
hl.curve("m3EmphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "global",     enabled = true, speed = 2.4, bezier = "m3StandardDecel" })
hl.animation({ leaf = "windows",    enabled = true, speed = 2.6, bezier = "m3EmphasizedDecel", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "m3StandardDecel",   style = "popin 94%" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 2.4, bezier = "m3EmphasizedDecel" })
hl.animation({ leaf = "border",     enabled = true, speed = 2.0, bezier = "m3StandardDecel" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2.0, bezier = "m3StandardDecel" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2.0, bezier = "m3StandardDecel",   style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.8, bezier = "m3EmphasizedDecel", style = "slide" })
