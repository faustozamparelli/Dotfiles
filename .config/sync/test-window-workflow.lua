-- Run with: lua ~/.config/sync/test-window-workflow.lua
-- Synthetic displays cover the second external screen without changing macOS.
local screens, windows, focused, alerts = {}, {}, nil, {}
local bindings, bindingMods, subscriptions = {}, {}, {}
local helperAvailable, tapCount, currentTap = true, 0, nil
local tasks = {}
local filter = {}
function filter:setOverrideFilter() return self end
function filter:setAppFilter() return self end
function filter:getWindows() return windows end
function filter:subscribe(events, callback)
    if type(events) ~= 'table' then events = {events} end
    for _, event in ipairs(events) do subscriptions[event] = callback end
end
local function noop() end
local function copy(t)
    local result = {}
    for key, value in pairs(t) do result[key] = value end
    return result
end
local function screen(id, x, y)
    return {
        id=function() return id end,
        getUUID=function() return tostring(id) end,
        fullFrame=function() return {x=x, y=y, w=1000, h=800} end,
        frame=function() return {x=x, y=y+25, w=1000, h=775} end,
        getBrightness=function(self) return self.brightness end,
        name=function(self) return self.displayName or 'Test Monitor' end,
    }
end
local function window(id, display, pid)
    local w = {display=display, rect=display:frame(), moves=0, standard=true}
    function w:id() return id end
    function w:isStandard() return self.standard end
    function w:isFullScreen() return false end
    function w:screen() return self.display end
    function w:frame() return copy(self.rect) end
    function w:setFrame(frame) self.rect = copy(frame); return self end
    function w:maximize() self.rect = self.display:frame(); return self end
    function w:moveToScreen(target)
        self.display = target
        self.moves = self.moves + 1
        self.rect = target:frame()
        return self
    end
    function w:focus() focused = self; return self end
    function w:raise() return self end
    function w:application()
        return {pid=function() return pid end, bundleID=function() return 'test.app' end}
    end
    function w:newWatcher() return {start=noop, stop=noop} end
    return w
end

hs = {
    autoLaunch=noop, dockIcon=noop, menuIcon=noop, consoleOnTop=noop,
    printf=noop,
    fs={attributes=function() return helperAvailable and {} or nil end},
    eventtap={event={types={systemDefined=14}}, new=function(_, callback)
        tapCount = tapCount + 1
        currentTap = {callback=callback, enabled=false}
        function currentTap:start() self.enabled=true; return self end
        function currentTap:stop() self.enabled=false end
        function currentTap:isEnabled() return self.enabled end
        return currentTap
    end},
    task={new=function(path, callback, args)
        local task = {path=path, callback=callback, args=args}
        function task:start() table.insert(tasks, self); return self end
        function task:terminate() self.terminated=true end
        return task
    end},
    window={
        filter={new=function() return filter end},
        focusedWindow=function() return focused end,
        get=function(id)
            for _, w in ipairs(windows) do if w:id() == id then return w end end
        end,
    },
    screen={
        allScreens=function() return copy(screens) end,
        find=function(id)
            for _, s in ipairs(screens) do if s:id() == id then return s end end
        end,
        watcher={new=function(callback)
            return {start=function(self) self.callback = callback; return self end}
        end},
    },
    axuielement={windowElement=function()
        return {isAttributeSettable=function() return true end}
    end},
    hotkey={bind=function(mods, key, callback)
        bindings[key], bindingMods[key] = callback, mods
    end},
    alert={show=function(message) table.insert(alerts, message) end},
    uielement={watcher={windowResized='resized'}},
    timer={doAfter=noop},
}
for _, event in ipairs({'windowMoved', 'windowFocused', 'windowVisible',
    'windowDestroyed', 'windowMinimized', 'windowHidden'}) do
    hs.window.filter[event] = event
end
package.preload['hs.ipc'] = function() return {} end
dofile(os.getenv('HOME') .. '/.hammerspoon/init.lua')

local checks = 0
local function check(condition, message)
    assert(condition, message)
    checks = checks + 1
end
for _, key in ipairs({'m','f','-','='}) do
    check(table.concat(bindingMods[key], ',') == 'cmd,ctrl,alt', 'original Super binding preserved: '..key)
end
for _, key in ipairs({'h','l','b'}) do
    check(table.concat(bindingMods[key], ',') == 'ctrl,alt', 'display controls stay off Super: '..key)
end
check(not bindings['1'] and not bindings['2'] and not bindings['3'], 'display number bindings removed')
local left, laptop, right = screen(40, -1000, 0), screen(1, 0, 0), screen(9, 1000, 0)
laptop.brightness = 0.5
screens = {right, laptop, left}
local a, b, elsewhere = window(1, laptop, 1), window(2, laptop, 2), window(3, right, 3)
windows, focused = {a, elsewhere, b}, a
local ordered = windowWorkflow.screens()
check(ordered[1] == left and ordered[2] == laptop and ordered[3] == right,
    'display order must follow arrangement, not enumeration or numeric ID')
windowWorkflow.send(1)
check(a.display == left and a.rect.w == 1000, 'send to first external and maximize')
windowWorkflow.send(3)
check(a.display == right, 'send to second external')
bindings['l']()
check(a.display == left, 'next display wraps from last to first')
bindings['h']()
check(a.display == right, 'previous display wraps from first to last')
windowWorkflow.send(2)
check(a.display == laptop, 'return to built-in display')

bindings['m']()
check(windowWorkflow.state().right == b:id() and elsewhere.moves == 0,
    'split must skip more recently focused apps on other screens')
check(a.rect.w == 500 and b.rect.x == 500, 'equal split on current display')
bindings['=']()
check(a.rect.w == 550 and b.rect.w == 450, 'existing split resize remains available')
local moves = a.moves
windowWorkflow.send(2)
check(windowWorkflow.state() ~= nil and a.moves == moves,
    'sending to the same display preserves the split')
focused = elsewhere
windowWorkflow.send(1)
check(windowWorkflow.state() ~= nil and a.rect.w == 550,
    'moving an unrelated window preserves the split')
focused = a
windowWorkflow.send(3)
check(windowWorkflow.state() == nil and b.display == laptop and b.rect.w == 1000,
    'moving a split member releases and maximizes its neighbor')
check(a.display == right and a.rect.w == 1000, 'moved split member maximizes on target')

windowWorkflow.send(2)
bindings['m']()
check(windowWorkflow.state() ~= nil, 'split can be recreated after a move')
a.display = left
subscriptions.windowMoved(a)
check(windowWorkflow.state() == nil and b.display == laptop,
    'dragging a split member to another display must not pull it back')

a.display, focused = laptop, a
bindings['m']()
screens = {left, right}
a.display, b.display = right, right
windowScreenWatcher.callback()
check(windowWorkflow.state() == nil and a.rect.w == 1000 and b.rect.w == 1000,
    'disconnecting the split display releases relocated windows')

screens = {laptop}
a.display, b.display, elsewhere.display = laptop, laptop, laptop
moves = a.moves
bindings['l'](); bindings['h']()
check(a.moves == moves, 'cycling with one display is a no-op')
windowWorkflow.send(3)
check(a.moves == moves and #alerts == 1, 'missing destination alerts without moving')
focused = nil
windowWorkflow.send(1); bindings['h']()
check(a.moves == moves, 'no focused window is safe')
focused, a.standard = a, false
windowWorkflow.send(1); bindings['l']()
check(a.moves == moves, 'fixed-size or nonstandard windows remain unmanaged')
a.standard = true

screens = {screen(8, 0, 800), laptop, screen(7, 0, -800)}
ordered = windowWorkflow.screens()
check(ordered[1]:id() == 7 and ordered[2] == laptop and ordered[3]:id() == 8,
    'vertically stacked displays use top-to-bottom order')

local function event(key, down, flags)
    return {systemKey=function() return {key=key,down=down} end,
        getFlags=function() return flags or {} end}
end
check(not windowWorkflow.brightnessEnabled() and tapCount == 0,
    'brightness starts off without creating an event tap or process')
screens, focused, a.display = {laptop}, a, laptop
bindings['b']()
check(not windowWorkflow.brightnessEnabled() and tapCount == 0,
    'built-in display alone does not activate brightness interception')
screens, helperAvailable = {laptop, left, right}, false
bindings['b']()
check(not windowWorkflow.brightnessEnabled() and tapCount == 0,
    'optional helper is never installed or started implicitly')
local ipad = screen(6, 1000, 0)
ipad.displayName = 'Sidecar Display (AirPlay)'
screens = {laptop, ipad}
bindings['b']()
check(not windowWorkflow.brightnessEnabled() and tapCount == 0 and #tasks == 0
    and alerts[#alerts]:find('Control Center'),
    'Sidecar-only setup explains native iPad brightness without requesting a helper')
screens = {laptop, left, right, ipad}
helperAvailable = true
bindings['b']()
check(windowWorkflow.brightnessEnabled() and #tasks == 0, 'enable is idle until a keypress')
check(not currentTap.callback(event('BRIGHTNESS_DOWN',true)) and #tasks == 0,
    'built-in brightness passes through to macOS')
a.display = ipad
check(not currentTap.callback(event('BRIGHTNESS_DOWN',true)) and #tasks == 0,
    'Sidecar never receives DDC commands even with a physical monitor connected')
a.display = left
check(not currentTap.callback(event('SOUND_UP',true)), 'unrelated media keys pass through')
check(not currentTap.callback(event('BRIGHTNESS_UP',true,{cmd=true})),
    'modified system shortcuts pass through')
check(currentTap.callback(event('BRIGHTNESS_UP',true)) and #tasks == 1
    and tasks[1].args[2] == left:getUUID() and tasks[1].args[5] == '5',
    'brightness starts one async helper addressed by focused display UUID')
check(currentTap.callback(event('BRIGHTNESS_UP',false)) and #tasks == 1,
    'key release is consumed without spawning a helper')
currentTap.callback(event('BRIGHTNESS_UP',true))
currentTap.callback(event('BRIGHTNESS_UP',true))
check(#tasks == 1, 'held keys never launch overlapping helper processes')
tasks[1].callback(0, 'Writing 15', '')
check(#tasks == 2 and tasks[2].args[5] == '10', 'queued repeats coalesce into one change')
tasks[2].callback(0, 'Writing 25', '')
a.display = right
currentTap.callback(event('BRIGHTNESS_DOWN',true,{shift=true}))
check(tasks[3].args[2] == right:getUUID() and tasks[3].args[5] == '-1',
    'second external screen and fine increments target the correct display')
bindings['b']()
check(not windowWorkflow.brightnessEnabled() and tasks[3].terminated,
    'off stops the event tap, active helper and queued work')
tasks[3].callback(0, '', '')
check(#tasks == 3, 'late completion after off cannot restart work')
screens = {right}
bindings['b']()
check(windowWorkflow.brightnessEnabled(), 'single external display works in closed-lid mode')
windowScreenWatcher.callback()
check(not windowWorkflow.brightnessEnabled(), 'display changes turn brightness mode off')
bindings['b']()
currentTap.callback(event('BRIGHTNESS_DOWN',true))
tasks[4].callback(1, 'DDC communication failure', '')
check(not windowWorkflow.brightnessEnabled(), 'DDC failure disables interception')
print(string.format('%d window workflow checks passed', checks))
