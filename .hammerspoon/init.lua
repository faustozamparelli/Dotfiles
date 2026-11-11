-- One desktop per display: maximize normal windows, with one optional app pair.
hs.window.animationDuration = 0
hs.window.setFrameCorrectness = true
hs.autoLaunch(false) -- Login is managed by com.fausto.window-workflow.
hs.dockIcon(false)
hs.menuIcon(true)
hs.consoleOnTop(false)
require('hs.ipc')

local super = {'cmd', 'ctrl', 'alt'} -- Karabiner's Right Command
local wf = hs.window.filter.new():setOverrideFilter({
    currentSpace = true, fullscreen = false, allowRoles = {'AXStandardWindow'},
}):setAppFilter('Hammerspoon', false)
local pair
local applying = false
local resizeWatchers = {}
local resized

local function normal(w)
    if not w or not w:id() or not w:isStandard() or w:isFullScreen() then return false end
    local app = w:application()
    -- Settings exposes a resizable AX window but constrains its layout.
    if not app or app:bundleID() == 'com.apple.systempreferences' then return false end
    local element = hs.axuielement.windowElement(w)
    return element and element:isAttributeSettable('AXSize')
        and element:isAttributeSettable('AXFullScreen')
end

local function maximize(w)
    if not normal(w) or not w:screen() then return end
    local a, b = w:frame(), w:screen():frame()
    if math.abs(a.x-b.x)>1 or math.abs(a.y-b.y)>1
        or math.abs(a.w-b.w)>1 or math.abs(a.h-b.h)>1 then
        w:maximize(0)
    end
end

local function finishSplit()
    for _, watcher in ipairs(resizeWatchers) do watcher:stop() end
    resizeWatchers = {}
    local old = pair
    pair = nil
    if old then
        maximize(hs.window.get(old.left))
        maximize(hs.window.get(old.right))
    end
end

-- Follow the arrangement in macOS Displays, independent of connection order.
local function orderedScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b)
        local af, bf = a:fullFrame(), b:fullFrame()
        if af.x ~= bf.x then return af.x < bf.x end
        if af.y ~= bf.y then return af.y < bf.y end
        return a:getUUID() < b:getUUID()
    end)
    return screens
end

local function sendToScreen(target)
    if not target then hs.alert.show('Display not connected'); return end
    local w = hs.window.focusedWindow()
    if not normal(w) or not w:screen() or w:screen():id() == target:id() then return end
    -- Moving one member releases its neighbor on the original display.
    if pair and (w:id() == pair.left or w:id() == pair.right) then finishSplit() end
    w:moveToScreen(target, false, true, 0)
    maximize(w)
    w:focus()
end

local function sendToDisplay(index)
    sendToScreen(orderedScreens()[index])
end

local function cycleDisplay(delta)
    local w = hs.window.focusedWindow()
    if not normal(w) or not w:screen() then return end
    local screens = orderedScreens()
    for i, screen in ipairs(screens) do
        if screen:id() == w:screen():id() then
            sendToScreen(screens[(i - 1 + delta) % #screens + 1])
            return
        end
    end
end

-- Optional, session-only DDC keys. No event tap or helper process while off.
local brightnessTap, brightnessTask
local brightnessPending = {}
local ddc = '/opt/homebrew/bin/m1ddc'
local function stopBrightness()
    if brightnessTap then brightnessTap:stop(); brightnessTap = nil end
    brightnessPending = {}
    if brightnessTask then brightnessTask:terminate(); brightnessTask = nil end
end

local function applyBrightness()
    if brightnessTask or not brightnessTap then return end
    local uuid, delta = next(brightnessPending)
    if not uuid then return end
    brightnessPending[uuid] = nil
    if delta == 0 then applyBrightness(); return end
    local task
    task = hs.task.new(ddc, function(code, output, err)
        if brightnessTask ~= task then return end
        brightnessTask = nil
        if code ~= 0 then
            stopBrightness()
            hs.printf('Display brightness: %s %s', output, err)
            hs.alert.show('Brightness control off: check monitor DDC/CI support')
            return
        end
        applyBrightness()
    end, {'display', uuid, 'chg', 'luminance', tostring(delta)})
    brightnessTask = task
    if not task or not task:start() then
        stopBrightness()
        hs.alert.show('Could not start m1ddc; brightness control off')
    end
end

local function toggleBrightness()
    if brightnessTap then
        stopBrightness()
        hs.alert.show('External brightness keys off')
        return
    end
    local hasExternal = false
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:getBrightness() == nil then hasExternal = true; break end
    end
    if not hasExternal then
        hs.alert.show('Connect a DDC display; native brightness stays with macOS')
        return
    end
    if not hs.fs.attributes(ddc) then
        hs.alert.show('Optional brightness helper missing: brew install m1ddc')
        return
    end
    brightnessTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, function(event)
        local key, flags = event:systemKey(), event:getFlags()
        if key.key ~= 'BRIGHTNESS_UP' and key.key ~= 'BRIGHTNESS_DOWN' then return false end
        if flags.cmd or flags.ctrl or flags.alt then return false end
        local w = hs.window.focusedWindow()
        local screen = w and w:screen() or hs.screen.mainScreen()
        -- Leave native brightness-capable displays to macOS.
        if not screen or screen:getBrightness() ~= nil then return false end
        if key.down then
            local uuid = screen:getUUID()
            local delta = (key.key == 'BRIGHTNESS_UP' and 1 or -1) * (flags.shift and 1 or 5)
            brightnessPending[uuid] = (brightnessPending[uuid] or 0) + delta
            applyBrightness()
        end
        return true
    end):start()
    if not brightnessTap:isEnabled() then
        stopBrightness()
        hs.alert.show('Brightness keys need Hammerspoon Accessibility permission')
        return
    end
    hs.alert.show('External brightness keys on: follows focused screen')
end

local function layout()
    if not pair then return end
    local left, right = hs.window.get(pair.left), hs.window.get(pair.right)
    local screen = hs.screen.find(pair.screen)
    if not normal(left) or not normal(right) or not screen
        or not left:screen() or not right:screen()
        or left:screen():id() ~= screen:id() or right:screen():id() ~= screen:id() then
        finishSplit()
        return
    end
    local f = screen:frame()
    local width = math.floor(f.w * pair.ratio)
    applying = true
    right:setFrame({x=f.x+width, y=f.y, w=f.w-width, h=f.h}, 0)
    left:setFrame({x=f.x, y=f.y, w=width, h=f.h}, 0)
    applying = false
end

local function toggleSplit()
    if pair then finishSplit(); return end
    local current = hs.window.focusedWindow()
    if not normal(current) or not current:screen() then return end
    local other
    for _, w in ipairs(wf:getWindows(hs.window.filter.sortByFocusedLast)) do
        if normal(w) and w:screen() and w:screen():id() == current:screen():id()
            and w:application():pid() ~= current:application():pid() then
            other = w
            break
        end
    end
    if not other then return end
    pair = {left=current:id(), right=other:id(), screen=current:screen():id(), ratio=0.5}
    layout()
    for _, w in ipairs({current, other}) do
        local watcher = w:newWatcher(function() resized(w) end)
        watcher:start({hs.uielement.watcher.windowResized})
        table.insert(resizeWatchers, watcher)
    end
    other:raise()
    current:focus()
end

local function resizeSplit(delta)
    if not pair then return end
    pair.ratio = math.max(0.25, math.min(0.75, pair.ratio + delta))
    layout()
end

-- km:windows.split
hs.hotkey.bind(super, 'm', toggleSplit)
-- km:windows.maximize
hs.hotkey.bind(super, 'f', function()
    finishSplit()
    maximize(hs.window.focusedWindow())
end)
-- km:windows.resize.left
hs.hotkey.bind(super, '-', function() resizeSplit(-0.05) end, nil,
    function() resizeSplit(-0.05) end)
-- km:windows.resize.right
hs.hotkey.bind(super, '=', function() resizeSplit(0.05) end, nil,
    function() resizeSplit(0.05) end)
-- km:windows.display.previous
hs.hotkey.bind(super, 'h', function() cycleDisplay(-1) end)
-- km:windows.display.next
hs.hotkey.bind(super, 'l', function() cycleDisplay(1) end)
-- km:windows.display.first
hs.hotkey.bind(super, '1', function() sendToDisplay(1) end)
-- km:windows.display.second
hs.hotkey.bind(super, '2', function() sendToDisplay(2) end)
-- km:windows.display.third
hs.hotkey.bind(super, '3', function() sendToDisplay(3) end)
-- km:windows.brightness.toggle
hs.hotkey.bind(super, 'b', toggleBrightness)

-- Keep the two app edges together when either window is resized by dragging.
resized = function(w)
    if applying then return end
    if not pair or (w:id() ~= pair.left and w:id() ~= pair.right) then maximize(w); return end
    local screen = hs.screen.find(pair.screen)
    if not screen or not w:screen() or w:screen():id() ~= screen:id() then
        finishSplit()
        return
    end
    local f, actual = screen:frame(), w:frame()
    local width = math.floor(f.w * pair.ratio)
    local expected = w:id() == pair.left and width or f.w - width
    if math.abs(actual.w - expected) < 2 then return end
    local boundary = w:id() == pair.left and actual.x + actual.w or actual.x
    pair.ratio = math.max(0.25, math.min(0.75, (boundary - f.x) / f.w))
    layout()
end
wf:subscribe(hs.window.filter.windowMoved, resized)

wf:subscribe({hs.window.filter.windowFocused, hs.window.filter.windowVisible}, function(w)
    if pair and (w:id() == pair.left or w:id() == pair.right) then
        local other = hs.window.get(w:id() == pair.left and pair.right or pair.left)
        if other then other:raise(); w:raise() end
    else
        maximize(w)
    end
end)
wf:subscribe({hs.window.filter.windowDestroyed, hs.window.filter.windowMinimized,
    hs.window.filter.windowHidden}, function(w)
    if pair and (w:id() == pair.left or w:id() == pair.right) then finishSplit() end
end)

-- Retain the watcher; reflow after a display or resolution change.
windowScreenWatcher = hs.screen.watcher.new(function()
    stopBrightness()
    if pair then layout() end
    for _, w in ipairs(wf:getWindows()) do
        if not pair or (w:id() ~= pair.left and w:id() ~= pair.right) then maximize(w) end
    end
end):start()
for _, w in ipairs(wf:getWindows()) do maximize(w) end

-- Small inspection surface for checks through the local Hammerspoon CLI.
windowWorkflow = {toggle=toggleSplit, finish=finishSplit, resize=resizeSplit,
    send=sendToDisplay, cycle=cycleDisplay, screens=orderedScreens,
    brightness=toggleBrightness,
    brightnessEnabled=function() return brightnessTap and brightnessTap:isEnabled() or false end,
    state=function() return pair end, windows=function() return wf:getWindows() end}

-- Remove old normal desktops at login; macOS moves their windows to a survivor.
-- Nothing opens Mission Control when each display already has one desktop.
hs.timer.doAfter(1, function()
    if not hs.accessibilityState() then return end
    local spaces, active = hs.spaces.allSpaces(), hs.spaces.activeSpaces()
    if not spaces or not active then return end
    local opened = false
    for display, ids in pairs(spaces) do
        local keep = active[display]
        for _, id in ipairs(ids) do
            if hs.spaces.spaceType(id) == 'user' and not keep then keep = id end
        end
        for i = #ids, 1, -1 do
            local id = ids[i]
            if id ~= keep and hs.spaces.spaceType(id) == 'user' then
                opened = true
                local ok, err = hs.spaces.removeSpace(id, false)
                if not ok then hs.printf('Desktop consolidation: %s', err) end
            end
        end
    end
    if opened then hs.spaces.closeMissionControl() end
end)
