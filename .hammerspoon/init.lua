-- One desktop: maximize normal windows, with one optional adjustable app pair.
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
    return w and w:id() and w:isStandard() and not w:isFullScreen()
        and hs.axuielement.windowElement(w):isAttributeSettable('AXSize')
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

local function layout()
    if not pair then return end
    local left, right = hs.window.get(pair.left), hs.window.get(pair.right)
    local screen = hs.screen.find(pair.screen)
    if not normal(left) or not normal(right) or not screen then
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
    if not normal(current) then return end
    local other
    for _, w in ipairs(wf:getWindows(hs.window.filter.sortByFocusedLast)) do
        if normal(w) and w:application():pid() ~= current:application():pid() then
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

-- Keep the two app edges together when either window is resized by dragging.
resized = function(w)
    if applying then return end
    if not pair or (w:id() ~= pair.left and w:id() ~= pair.right) then maximize(w); return end
    local screen = hs.screen.find(pair.screen)
    if not screen then finishSplit(); return end
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
    if pair then layout() end
    for _, w in ipairs(wf:getWindows()) do
        if not pair or (w:id() ~= pair.left and w:id() ~= pair.right) then maximize(w) end
    end
end):start()
for _, w in ipairs(wf:getWindows()) do maximize(w) end

-- Small inspection surface for checks through the local Hammerspoon CLI.
windowWorkflow = {toggle=toggleSplit, finish=finishSplit, resize=resizeSplit,
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
