-- ============================================================================
-- Monitor Layout
-- Left:  DP-1 (Dell E1916H, 1366x768)
-- Right: DP-3 (Dell S2421HS, 1920x1080, Primary)
-- ============================================================================

hl.monitor({
    output   = "DP-1",
    mode     = "1366x768@59.79",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@60.00",
    position = "1366x0",
    scale    = 1,
})

-- Fallback for any additional plugged displays
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
