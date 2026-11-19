-- ============================================================================
-- Layout (Dwindle) & Critically-Damped Fluid Motion
-- ============================================================================

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
        special_scale_factor = 0.94,
        use_active_for_splits = true,
        default_split_ratio = 1.0,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.55,
    },

    animations = {
        enabled = true,
        workspace_wraparound = false,
    },
})

-- Crisp, responsive physics without rubbery bounce or spinning border loops
hl.curve("fluidSpring", { type = "spring", mass = 0.8, stiffness = 360, damping = 28 })
hl.curve("outQuint",    { type = "bezier", points = { { 0.22, 1.0 }, { 0.36, 1.0 } } })
hl.curve("outExpo",     { type = "bezier", points = { { 0.16, 1.0 }, { 0.30, 1.0 } } })
hl.curve("inOutCubic",  { type = "bezier", points = { { 0.65, 0.0 }, { 0.35, 1.0 } } })

hl.animation({ leaf = "global",      enabled = true, speed = 5.0, bezier = "outQuint" })
hl.animation({ leaf = "windows",     enabled = true, speed = 4.2, spring = "fluidSpring", style = "popin 90%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.0, spring = "fluidSpring", style = "popin 88%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3.0, bezier = "outExpo",     style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, spring = "fluidSpring" })

hl.animation({ leaf = "border",      enabled = true, speed = 4.0, bezier = "outQuint" })
hl.animation({ leaf = "borderangle", enabled = false })

hl.animation({ leaf = "fade",          enabled = true, speed = 3.4, bezier = "outQuint" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3.4, bezier = "outQuint" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2.8, bezier = "outQuint" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 3.8, bezier = "outQuint" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 3.8, bezier = "outQuint" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 3.8, bezier = "outQuint" })
hl.animation({ leaf = "fadePopups",    enabled = true, speed = 3.5, bezier = "outExpo" })
hl.animation({ leaf = "fadePopupsIn",  enabled = true, speed = 3.5, bezier = "outExpo" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 2.5, bezier = "outQuint" })

hl.animation({ leaf = "layers",        enabled = true, speed = 3.8, bezier = "outExpo", style = "popin 94%" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.6, bezier = "outExpo", style = "popin 93%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2.6, bezier = "outQuint", style = "popin 95%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3.2, bezier = "outQuint" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.4, bezier = "outQuint" })

hl.animation({ leaf = "workspaces",          enabled = true, speed = 4.6, spring = "fluidSpring", style = "slidefade 14%" })
hl.animation({ leaf = "workspacesIn",        enabled = true, speed = 4.6, spring = "fluidSpring", style = "slidefade 14%" })
hl.animation({ leaf = "workspacesOut",       enabled = true, speed = 4.6, spring = "fluidSpring", style = "slidefade 14%" })
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 4.2, spring = "fluidSpring", style = "slidefadevert -14%" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4.2, spring = "fluidSpring", style = "slidefadevert -14%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3.6, bezier = "outExpo",     style = "slidefadevert -14%" })
hl.animation({ leaf = "zoomFactor",          enabled = true, speed = 4.5, bezier = "outQuint" })
