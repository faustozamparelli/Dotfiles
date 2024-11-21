local wezterm = require("wezterm")
local config = wezterm.config_builder()
config.disable_default_key_bindings = true
local keybindings = require("keybindings")
config.keys = keybindings

config.default_prog = { "/opt/homebrew/bin/fish" }

config.color_scheme = "Wez (Gogh)"
config.colors = {
    background = "rgb(0, 0, 0)",
}
config.font = wezterm.font("Hack Nerd Font Mono", { weight = "Regular" })
config.font_size = 14

config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.enable_scroll_bar = false

config.initial_cols = 141
config.initial_rows = 62

-- config.window_background_image = "/Users/faustozamparelli/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Wallpapers/Warp/Warp-1.jpg"
-- config.window_background_image_hsb = {
--     brightness = 0.1
-- }

return config
