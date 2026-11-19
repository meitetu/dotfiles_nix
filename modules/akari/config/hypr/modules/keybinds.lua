-- ============================================================================
-- Keybindings (Inherited user workflow + Dwindle tiling + Wofi + Quickshell)
-- ============================================================================

local mainMod = "SUPER"
local bin     = "$HOME/.local/bin"

-- ----------------------------------------------------------------------------
-- Applications & Launchers
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(bin .. "/akari-wofi drun"))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(bin .. "/akari-wofi drun"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(bin .. "/akari-wofi run"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("floorp"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd(bin .. "/akari-ctl lock"))

-- Wofi Utilities (Clipboard, Emoji, Wallpaper, Power)
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd(bin .. "/akari-wofi clip"))
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd(bin .. "/akari-wofi emoji"))
hl.bind(mainMod .. " + SLASH",  hl.dsp.exec_cmd(bin .. "/akari-wofi emoji"))
hl.bind(mainMod .. " + Y",      hl.dsp.exec_cmd(bin .. "/akari-wofi wallpaper"))

-- Quickshell Panels & Overlays
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd(bin .. "/akari-ctl panel-toggle"))
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd(bin .. "/akari-ctl panel-toggle"))
hl.bind(mainMod .. " + X",      hl.dsp.exec_cmd(bin .. "/akari-ctl power-toggle"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(bin .. "/akari-ctl power-toggle"))
hl.bind(mainMod .. " + F1",     hl.dsp.exec_cmd(bin .. "/akari-ctl cheatsheet-toggle"))
hl.bind(mainMod .. " + G",      hl.dsp.exec_cmd(bin .. "/akari-ctl cheatsheet-toggle"))
hl.bind(mainMod .. " + O",      hl.dsp.exec_cmd(bin .. "/akari-ctl panel-toggle"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(bin .. "/akari-ctl sysmon-toggle"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(bin .. "/akari-ctl bar-toggle"))

-- ----------------------------------------------------------------------------
-- Window Management (Dwindle + Floating + Groups)
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.exec_cmd(bin .. "/hypr_float_maximize.sh"))
hl.bind(mainMod .. " + T",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + ALT + F",   hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.cycle_next({ floating = true }))
hl.bind(mainMod .. " + C",         hl.dsp.window.center())
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))

-- Tabbed window groups
hl.bind(mainMod .. " + W",           hl.dsp.group.toggle())
hl.bind(mainMod .. " + TAB",         hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.group.prev())

-- Focus movement (Arrow keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Window movement in Dwindle / Floating (Mod + Alt + Arrow, preserved from user config)
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.move({ direction = "down" }))

-- Window swap in Dwindle (Mod + Shift + Arrow)
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))

-- Resize active window (Mod + Minus / Equal)
hl.bind(mainMod .. " + minus",         hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + equal",         hl.dsp.window.resize({ x = 80,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 80,  relative = true }), { repeating = true })

-- Mouse drag & resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ----------------------------------------------------------------------------
-- Workspaces (1..10, U/I, Mouse Wheel, Special "magic" Scratchpad)
-- ----------------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + U",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + I",        hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + U", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.window.move({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse_down",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",          hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + mouse_up",   hl.dsp.window.move({ workspace = "r-1" }))

-- Scratchpad "magic" (Minimize / Restore)
hl.bind(mainMod .. " + S",            hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + up",   hl.dsp.exec_cmd(bin .. "/akari-unminimize"))

-- ----------------------------------------------------------------------------
-- Screenshots
-- ----------------------------------------------------------------------------
hl.bind("PRINT",                   hl.dsp.exec_cmd(bin .. "/akari-screenshot full"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(bin .. "/akari-screenshot region"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.exec_cmd(bin .. "/akari-screenshot window"))

-- ----------------------------------------------------------------------------
-- Audio, Brightness & Media Keys (Connected to Quickshell OSD)
-- ----------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(bin .. "/akari-ctl volume-up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(bin .. "/akari-ctl volume-down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(bin .. "/akari-ctl volume-mute"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(bin .. "/akari-ctl mic-mute"),        { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(bin .. "/akari-ctl brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(bin .. "/akari-ctl brightness-down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Session Exit
hl.bind(mainMod .. " + M",         hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(bin .. "/akari-ctl power-toggle"))
hl.bind("CTRL + ALT + DELETE",     hl.dsp.exit())
