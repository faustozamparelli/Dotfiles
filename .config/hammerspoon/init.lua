-- Define Hyper key
local hyper = {"cmd", "ctrl", "alt"}

-- Map keys to apps
local appKeys = {
    f = "Google Chrome",
    d = "Obsidian",
    s = "Spotify",
    j = "Ghostty", 
		k = "Cursor"
}

-- Function to toggle a single app
local function toggleApp(appName)
    local app = hs.application.find(appName)
    if not app then
        -- App not running → launch it
        hs.application.launchOrFocus(appName)
    elseif app:isFrontmost() then
        -- App is frontmost → hide it
        app:hide()
    else
        -- App is running but not frontmost → focus it
        app:activate()
    end
end

-- Bind hotkeys
for key, apps in pairs(appKeys) do
    hs.hotkey.bind(hyper, key, function()
        if type(apps) == "table" then
            -- Multiple apps for one key
            for _, appName in ipairs(apps) do
                toggleApp(appName)
            end
        else
            toggleApp(apps)
        end
    end)
end
