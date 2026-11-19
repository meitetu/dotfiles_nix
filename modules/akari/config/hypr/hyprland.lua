-- ============================================================================
-- Akari Hoshizaki Desktop Theme (ASTERISM Edition) for Hyprland 0.57+
-- Entry point: ~/.config/hypr/hyprland.lua
-- ============================================================================

require("modules/theme")
require("modules/monitors")
require("modules/env")
require("modules/autostart")
require("modules/layout")
require("modules/rules")
require("modules/keybinds")

-- Optional user overrides (preserved across theme updates)
local user_cfg = os.getenv("HOME") .. "/.config/hypr/user.lua"
local f = io.open(user_cfg, "r")
if f then
    f:close()
    pcall(dofile, user_cfg)
end
