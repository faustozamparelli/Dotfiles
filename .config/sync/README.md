# Fausto's Terminal Workspace Manual

This is the single human and agent manual for this dotfiles setup. It explains
the working model, the custom keymaps, the terminal tools already installed,
and the rules for safely changing or synchronizing the configuration.

The primary workspace is VS Code for editing and Ghostty with Herdr for terminal sessions.

The compact workflow and tool map is `~/README.md`; agents can use
`$fausto-workflow` from `~/.codex/skills/fausto-workflow/SKILL.md`. This manual
retains detailed procedures and validation evidence.

## App Sync

On Air and Pro, `mac-update` checks eligibility every 30 minutes while awake
and starts one Homebrew update pass per local calendar day when the desktop
is unlocked and keyboard/mouse activity occurred within ten minutes. It does
not wake the Mac or prevent sleep. `brew update` refreshes metadata, then
unpinned formulae upgrade and outdated cask archives download, including for
open apps. Downloads use `brew fetch --cask`, which does not quit or replace
the installed app. Closed apps then upgrade; open apps remain in a persistent
pending queue. Subsequent active checks (every 30 minutes while the Mac is in use)
finish queued installs without another metadata refresh, formula upgrade or
download pass that day. If another tool changes the target version, the queue
waits for the next daily download. Native updaters may also finish on app exit.
Processes are checked again after downloading; Homebrew receives `--no-quit`
as well. The user-approved policy (2026-11-06) is to download while working and
finish after closing, without automatically quitting or restarting apps.
Installer/service casks still download but require their native updater or
interactive approval to install. Login-item stanzas (preserved by Homebrew on
upgrade) and app-only ShipIt updater helpers are allowed for closed apps.
VPNs, other services and arbitrary lifecycle scripts remain deferred; sudo
is disabled for this job. Offline metadata refreshes retry at the next eligible
check; failed downloads or installs retry on the next daily pass. Pins and direct installers
(Task Timer and OpenFOAM v2306) keep their reviewed versions. Formula upgrades
can still affect live command-line environments; no service restart is requested.

`mac-update --install` installs the Aqua-only login agent. Setup and each fresh
daily pass enable bundled Sparkle automatic checks/downloads with a daily
interval, including apps installed directly and nested frameworks such as
Helium's. Native updaters apply their own authorization and restart
rules ([Sparkle settings](https://sparkle-project.org/documentation/customization/)).
Where Microsoft AutoUpdate is installed (Pro), setup enables its automatic
download/install mode ([Microsoft preferences](https://learn.microsoft.com/en-us/microsoft-365-apps/mac/mau-preferences)).
App Store updates use Apple's separate Automatic Updates setting; Air already
has it enabled, while Pro needs it enabled in App Store > Settings (or with
`sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true`).
The daily job does not run privileged `mas update`, macOS upgrades, or arbitrary
package-manager self-updates. Safari web apps update with their websites.

Inspect with `mac-update --status`, `mac-update --dry-run`, and
`tail -100 ~/Library/Logs/mac-update.log`. Use `mac-update --now` to request
an extra download pass; it retains the running-app and installer safeguards.
The `pending` field in `--status` lists cached versions awaiting installation. State is
machine-local in `~/.local/state/app-updates/`. Reinstall with
`mac-update --install`; remove the schedule with
`launchctl bootout gui/$(id -u)/com.fausto.app-updates` and remove
`~/Library/LaunchAgents/com.fausto.app-updates.plist`. Native updater preferences
are separate and can be changed in each app. Verification commands:
`/usr/bin/python3 ~/.config/sync/test-app-updates.py` and `mac-update --dry-run`.
Validation (2026-11-05): seven isolated updater tests passed on each laptop,
42 existing sync tests passed on Air, both generated plists passed lint and
both agents loaded. Air's first real pass refreshed Homebrew and started the
Copilot CLI upgrade. macOS denied writing Air's sandboxed ProtonVPN preferences;
enable its updater inside the app. Air also lacks Microsoft AutoUpdate, so
Excel needs an interactive installer update. These are pending local actions;
neither all apps being current nor future scheduled runs are claimed verified.
Validation (2026-11-06): 15 updater tests passed on Air and Studio; 42 existing
sync tests passed on Air. Coverage includes open-app downloads,
installation after closing without a second daily fetch, an app opening during
download, native-updater completion, metadata changes, failed downloads, nested
Sparkle discovery, and preserved login items/ShipIt helpers. Studio retains
the previously requested one-time update scope; no schedule is installed there.
A live Air run cached updates for running Codex and Helium without closing
them. Post-close installation is covered by the isolated tests; a real user
quit event has not yet been observed. Pro was unreachable over Tailscale and
its LAN hostname did not resolve, so deployment there remains pending.

Use `mac-app` to install and publish application choices on this Mac. On
other Macs, review incoming dotfiles, then run `mac-sync --pull` to apply them:

```sh
mac-app firefox
mac-app share --mas 497799835 Xcode
mac-app local transmission
mac-app temporary handbrake
mac-app skip firefox
mac-app remove firefox
```

Homebrew casks are the default source. App Store apps use their numeric ID,
and exceptional direct downloads use a reviewed checksum-pinned installer.
Shared command-line utilities are deliberately curated in
`~/.config/mac-setup/packages.txt`; arbitrary formulae remain temporary and
local. `mac-sync --nuke` removes temporary formulae while retaining dependencies
still needed by the curated set. The sync removes apps only when they are
explicitly recorded for retirement.

## Ghostty and Herdr Terminal Workspace

Open Ghostty to attach fish to the persistent Herdr session. Open a project
with `code path/to/project`; shell and Git use `/usr/bin/nano` when they need
an editor. Herdr keeps terminal work and Codex sessions available.

## The Mental Model

### Ghostty is only the outer window

Ghostty displays the terminal and translates macOS Command and Option chords
into Kitty keyboard events. It deliberately does not own tabs or splits;
Herdr owns the workspace layout. Closing Ghostty does not end the Herdr server.

### Herdr owns workspaces

A Herdr session contains workspaces, each workspace contains tabs, and each tab
contains panes:

```text
session: default
├── workspace: project-a
│   └── tab 1: editor
│   ├── pane: shell
│   └── pane: Codex
└── workspace: project-b
    └── tab 1: editor
    ├── pane: shell
    └── pane: shell
```

Use one Herdr workspace per project and tabs for independent layouts within
that project. A pane is a temporary view, not a substitute for a project. New
panes, tabs, and workspaces inherit the current pane's directory.

The shell working directory defines the scope of terminal commands.

## Windows on One Desktop

OmniWM was retired on 2026-11-05. Its config, capture helpers and bindings
are removed; retired-apps.tsv prevents reinstall and mac-sync cleans its data.

The com.fausto.window-workflow LaunchAgent runs Hammerspoon 1.1.1
with ~/.hammerspoon/init.lua at login. System Settings and windows without settable AXSize/AXFullScreen attributes are
left unmanaged by maximization and split pairing. Normal resizable
windows maximize when shown or focused, except the active split pair. Dialogs,
launchers and fixed-size utility windows keep their native size. Command-Tab
retains normal macOS behavior. No fullscreen Spaces are created.

Super is Right Command (Control + Option + Command), supplied by Karabiner.
Super-M puts the current app on the left and the most recently focused other
app **on that display** on the right. Press it again to maximize both. Super-F
also exits the split and maximizes the focused window. Super-minus/plus moves the split boundary
left/right by five percentage points (plus is = without Shift). Dragging the
inner edge also resizes its neighbor. The boundary is limited to 25-75 percent;
application minimum sizes still apply. Closing, minimizing or hiding either
member maximizes the survivor. Other apps stay maximized when switched to.

Ctrl-Option-H/L sends the focused window to the previous/next display, wrapping
around in left-to-right macOS Display Settings order (top to bottom for vertically
aligned screens). This covers the built-in display plus two externals, including
Sidecar. With two screens either key sends to the other screen; with one it does
nothing. Super retains the original maximize/split controls; the added Super
display/brightness bindings and display-number shortcuts were removed. The moved
window maximizes and keeps focus. Moving or dragging a split member to another
screen ends the split and maximizes its neighbor on the original screen.

Physical-monitor brightness is optional and **off at startup**. Ctrl-Option-B
enables/disables the normal brightness keys for this session. They target the
focused physical monitor; Shift uses one monitor unit instead of five. Native Apple brightness and
modified system shortcuts pass through. A display change or DDC failure turns the
mode off. Off means no brightness event tap, timer, polling or helper process.
While enabled, keypresses run the small [m1ddc](https://github.com/waydabber/m1ddc)
CLI asynchronously, serializing/coalescing held keys and addressing each monitor
by its system UUID. DDC/CI must be supported and enabled on the monitor/connection;
there is no software-dimming fallback. `brew install m1ddc` is an optional,
machine-local install (1.3.1, 85 KB on Pro); no app, login item or shared package
entry is added. Air/Studio do not install it automatically. `mac-sync --nuke`
may remove this optional formula; reinstall it only when wanted. MonitorControl
was removed after Fausto chose this lighter approach; no shared setup remains.

Sidecar/AirPlay display names are excluded from DDC control. When only the iPad
is connected, Ctrl-Option-B explains the native alternative and starts no listener
or helper. Adjust actual iPad brightness in its Control Center: swipe down from
the top-right edge and drag the brightness slider ([Apple](https://education.apple.com/learning-center/T021988A-en_US)).
[BetterDisplay's brightness guide](https://betterdisplay.pro/guide/faq/brightness/monitor-percentage-mismatch/)
confirms that its Sidecar dimming changes the image, not the iPad's brightness setting.

Portrait Sidecar research (2026-11-11): native Sidecar normally provides a landscape
desktop; simply rotating the iPad can crop/letterbox it. [BetterDisplay's portrait
guide](https://betterdisplay.pro/guide/tutorials/rotated-sidecar/) documents a Pro
virtual portrait display streamed/rotated onto Sidecar. It requires Screen Recording,
must remain running during use, and adds capture/render work. It can be kept out
of login startup and used only for portrait sessions. Hide Sidecar's sidebar/Touch
Bar; keep Sidecar's own session in landscape (landscape rotation lock can prevent
cropping), then use the virtual portrait desktop. Prefer USB/lower resolution/FPS
if slow. A smaller [experimental portrait project](https://github.com/toho-stdio/sidecar-portrait-macos)
uses ScreenCaptureKit/Metal and can quit after a session, but its README lists
keyboard-forwarding limitations; compatibility, input and overhead are unverified
here. Neither portrait app was installed. Lowest added overhead remains native
Sidecar in landscape with brightness adjusted on the iPad itself.

Window frame changes have zero animation duration. window-defaults.sh disables
window/Dock animations, disables Stage Manager and tile
margins, and sets title-bar double-click to Fill. Some apps read these defaults
only at next launch. Reduce Motion is left unchanged at the user's request.
macOS/app-controlled transitions may still occur.

Accessibility permission for Hammerspoon is machine-local and must be granted
in System Settings > Privacy & Security > Accessibility on each Mac. The
configuration does not alter privacy databases. Studio has no logged-in desktop
at setup time, so desktop behavior there requires a console login to verify.

Verification (2026-11-05): Air passed 13 live assertions for maximize, current/
last-used app selection, equal split, keyboard resize, AX resize notifications,
paired edges, switching away/back, 25-75 percent bounds and return to maximize.
The resize notification check simulates a border resize through AX; physical
pointer dragging was not tested. Initial checks caught reversed focus ordering
and the filter's 0.5-second resize debounce; focus ordering now uses newest-first,
and the pair observes native resize notifications directly. The regular checks
passed; the OmniWM retirement test also verifies idempotence and preservation of
Karabiner settings. Pro passed 12 matching live checks after authorization and
relaunch; the third-app check was omitted because only two normal windows were
open. Air and Pro each reported one desktop. Studio has no console
login; its nine old desktops are scheduled for consolidation after login and
Accessibility authorization. Consolidation there remains unverified.

Inspect with `hs -c 'print(hs.accessibilityState()); print(hs.inspect(hs.spaces.allSpaces()))'`.
Exercise the layout with `hs -c 'windowWorkflow.toggle()'`,
`hs -c 'windowWorkflow.resize(0.05)'` and `hs -c 'windowWorkflow.finish()'`.
Run `lua ~/.config/sync/test-window-workflow.lua` for the display/brightness checks.
Verification (2026-11-11, Pro): 38 isolated checks passed, covering three-screen
ordering, wraparound, missing destinations, split moves/unplug, optional helper
absence, default-off behavior, native-key passthrough, UUID targeting, serialized
repeats, failures and shutoff. The 42 existing sync tests also passed. Three live
checks passed for a portrait external, return to the built-in display and cycling.
An initial recent-app split assertion failed during interactive focus changes;
a controlled rerun verified recent-app selection, split, resize and paired edges,
then restored the windows and focus.
`m1ddc` read hardware luminance 10 from the attached Samsung display. The display
was disconnected before the read/change/restore and brightness-key checks, so
hardware writes and physical keys remain unverified. Brightness was left off.
Air's LAN name did not resolve; Studio's Tailscale IP timed out with Pro's VPN off.
Their rollout remains pending; Pro's existing VPN state was preserved.
Follow-up (2026-11-11): 48 isolated checks passed after moving display controls to
Ctrl-Option and preserving the four original Super bindings. Pro reported Sidecar
as AirPlay/virtual display ID 6; Hammerspoon native brightness returned nil and
`m1ddc display list` omitted it, confirming this connection has no DDC target.
Both new Ctrl-Option-H/L shortcuts moved a real window between Pro and Sidecar;
the original frame was restored. Sidecar-only brightness activation stayed off,
with no helper process. Physical-monitor DDC writes remain unverified. Air/Studio
connection probes failed again; their rollout remains pending.

## Keyboard Layers

The configuration assigns each modifier a stable job:

- `Right Cmd` (`Super`): original global macOS maximize/split controls.
- `Ctrl-Option-h/l`: send windows between displays; `Ctrl-Option-b`: optional physical-monitor DDC brightness mode.
- `Ctrl-h/l`: move between Herdr workspaces.
- `Cmd`: frequent Herdr tab and pane operations.
- `Alt`: directional Herdr pane focus; adding Shift resizes.
- `Ctrl-Space`: Herdr administration and infrequent operations.
- Other `Ctrl` keys retain conventional terminal and editor behavior.

The notation `Ctrl-Space c` means press `Ctrl-Space`, release it, then press
`c`. The notation `Cmd-g` means hold Command while pressing `g`.

## Custom Keymap Reference

This table is generated from `~/.config/keymaps/registry.tsv`. Agents must
update the registry and implementation together, then run `keymap-docs`.

<!-- KEYMAPS:START -->
| Layer | Category | Key | Behavior |
|---|---|---|---|
| Karabiner | Super | `Right Cmd` | Hold the global Super modifier |
| Karabiner | Key | `§` | Hold the § key for Wispr Flow dictation |
| Karabiner | Fn | `Fn-h` | Move left with a physical arrow equivalent |
| Karabiner | Fn | `Fn-j` | Move down with a physical arrow equivalent |
| Karabiner | Fn | `Fn-k` | Move up with a physical arrow equivalent |
| Karabiner | Fn | `Fn-l` | Move right with a physical arrow equivalent |
| Ghostty | Command | `Cmd-a` | Leave the current editing mode |
| Fish | Completion | `Tab` | Search command completions with fzf and Carapace |
| Fish | Completion | `Shift-Tab` | Open the native Fish completion menu |
| Fish | Control | `Ctrl-r` | Search command history with fzf |
| Herdr | Command | `Cmd-h` | Select the previous tab |
| Herdr | Command | `Cmd-l` | Select the next tab |
| Herdr | Command | `Cmd-Shift-h` | Move the current tab left |
| Herdr | Command | `Cmd-Shift-l` | Move the current tab right |
| Herdr | Command | `Cmd-r` | Rename the current tab |
| Herdr | Command | `Cmd-b` | Create a pane on the right |
| Herdr | Command | `Cmd-n` | Create a pane below |
| Herdr | Command | `Cmd-g` | Create or focus the full-size Codex tab |
| Herdr | Command | `Cmd-w` | Close the current pane |
| Herdr | Command | `Cmd-t` | Create a tab in the current workspace |
| Herdr | Command | `Cmd-Shift-u` | Enter keyboard copy mode |
| Herdr | Control | `Ctrl-h` | Switch to the previous workspace |
| Herdr | Control | `Ctrl-l` | Switch to the next workspace |
| Herdr | Alt | `Alt-h` | Focus the pane to the left |
| Herdr | Alt | `Alt-j` | Focus the pane below |
| Herdr | Alt | `Alt-k` | Focus the pane above |
| Herdr | Alt | `Alt-l` | Focus the pane to the right |
| Herdr | Alt | `Alt-Shift-h` | Resize the pane left |
| Herdr | Alt | `Alt-Shift-j` | Resize the pane down |
| Herdr | Alt | `Alt-Shift-k` | Resize the pane up |
| Herdr | Alt | `Alt-Shift-l` | Resize the pane right |
| Herdr | Ctrl-Space | `c` | Create a tab in the current workspace |
| Herdr | Ctrl-Space | `p` | Select the previous tab |
| Herdr | Ctrl-Space | `n` | Select the next tab |
| Herdr | Ctrl-Space | `Shift-t` | Rename the current tab |
| Herdr | Ctrl-Space | `Alt-Left` | Move the current tab left |
| Herdr | Ctrl-Space | `Alt-Right` | Move the current tab right |
| Herdr | Ctrl-Space | `1..9` | Switch directly to tab 1-9 |
| Herdr | Ctrl-Space | `Shift-x` | Close the current tab |
| Herdr | Ctrl-Space | `Shift-n` | Create and switch to a named workspace |
| Herdr | Ctrl-Space | `w` | Navigate workspaces |
| Herdr | Ctrl-Space | `g` | Search workspaces, tabs, panes, and agents |
| Herdr | Ctrl-Space | `Shift-g` | Create a Git worktree |
| Herdr | Ctrl-Space | `Shift-o` | Open an existing Git worktree |
| Herdr | Ctrl-Space | `Alt-x` | Remove a managed Git worktree after confirmation |
| Herdr | Ctrl-Space | `Shift-w` | Rename the current workspace |
| Herdr | Ctrl-Space | `Shift-d` | Close the current workspace after confirmation |
| Herdr | Ctrl-Space | `Shift-Left` | Switch to the previous workspace |
| Herdr | Ctrl-Space | `Shift-Right` | Switch to the next workspace |
| Herdr | Ctrl-Space | `Shift-1..9` | Switch directly to workspace 1-9 |
| Herdr | Ctrl-Space | `[` | Focus the previous agent |
| Herdr | Ctrl-Space | `]` | Focus the next agent |
| Herdr | Ctrl-Space | `Alt-1..9` | Focus agent 1-9 |
| Herdr | Ctrl-Space | `v` | Create a pane on the right |
| Herdr | Ctrl-Space | `-` | Create a pane below |
| Herdr | Ctrl-Space | `x` | Close the current pane |
| Herdr | Ctrl-Space | `Shift-p` | Rename the current pane |
| Herdr | Ctrl-Space | `e` | Open pane scrollback in the editor |
| Herdr | Ctrl-Space | `u` | Enter keyboard copy mode |
| Herdr | Ctrl-Space | `h` | Focus the pane to the left |
| Herdr | Ctrl-Space | `j` | Focus the pane below |
| Herdr | Ctrl-Space | `k` | Focus the pane above |
| Herdr | Ctrl-Space | `l` | Focus the pane to the right |
| Herdr | Ctrl-Space | `Shift-h` | Swap the current pane left |
| Herdr | Ctrl-Space | `Shift-j` | Swap the current pane down |
| Herdr | Ctrl-Space | `Shift-k` | Swap the current pane up |
| Herdr | Ctrl-Space | `Shift-l` | Swap the current pane right |
| Herdr | Ctrl-Space | `Tab` | Cycle to the next pane |
| Herdr | Ctrl-Space | `Shift-Tab` | Cycle to the previous pane |
| Herdr | Ctrl-Space | `Backspace` | Return to the last focused pane |
| Herdr | Ctrl-Space | `z` | Toggle pane zoom |
| Herdr | Ctrl-Space | `r` | Enter pane resize mode |
| Herdr | Ctrl-Space | `b` | Toggle the sidebar |
| Herdr | Ctrl-Space | `,` | Open Herdr settings |
| Herdr | Ctrl-Space | `o` | Open the current notification target |
| Herdr | Ctrl-Space | `d` | Detach the Herdr client |
| Herdr | Ctrl-Space | `Shift-r` | Reload Herdr configuration |
| Herdr | Ctrl-Space | `?` | Open searchable keymap help |
| VS Code | Command | `Cmd-h` | Select the previous editor tab |
| VS Code | Command | `Cmd-l` | Select the next editor tab |
| VS Code | Command | `Cmd-Shift-h` | Move the current editor tab left |
| VS Code | Command | `Cmd-Shift-l` | Move the current editor tab right |
| VS Code | Command | `Cmd-b` | Split the editor to the right |
| VS Code | Command | `Cmd-n` | Split the editor below |
| VS Code | Command | `Cmd-w` | Close the active editor tab |
| VS Code | Command | `Cmd-t` | Show the terminal in an editor tab or return to the previous file |
| VS Code | Command | `Cmd-Shift-t` | Open a terminal beside the editor |
| VS Code | Command | `Cmd-j` | Show or hide the file explorer |
| VS Code | Command | `Cmd-Shift-j` | Show or hide the secondary sidebar |
| VS Code | Command | `Cmd-k` | Show or hide Source Control |
| Hammerspoon | Super | `Super-m` | Toggle current and last-used app between split and maximized |
| Hammerspoon | Super | `Super-f` | Maximize and leave the current split |
| Hammerspoon | Super | `Super--` | Move the split boundary left by five percentage points |
| Hammerspoon | Super | `Super-+ (=/+ key, no Shift)` | Move the split boundary right by five percentage points |
| Hammerspoon | Control-Alt | `Ctrl-Alt-h` | Send the focused window to the previous display, wrapping around |
| Hammerspoon | Control-Alt | `Ctrl-Alt-l` | Send the focused window to the next display, wrapping around |
| Hammerspoon | Control-Alt | `Ctrl-Alt-b` | Toggle optional physical-monitor DDC brightness keys (off by default; excludes Sidecar) |
<!-- KEYMAPS:END -->

## Herdr in Practice

### Workspaces

The sidebar shows workspaces, tabs, panes, Git context, and agent state. Herdr
workspaces replace the old tmux sessions; tabs replace tmux windows.

- `Ctrl-h` and `Ctrl-l` switch workspaces.
- `Ctrl-Space Shift-n` asks for a name, then creates a workspace.
- `Ctrl-Space Shift-d` asks for confirmation, then closes the current workspace.
- `Ctrl-Space w` opens workspace navigation.
- `Ctrl-Space g` searches workspaces, tabs, panes, and agents.

### Tabs and panes

- `Cmd-h` and `Cmd-l` move between tabs.
- `Cmd-Shift-h` and `Cmd-Shift-l` reorder the current tab.
- `Cmd-t` creates a tab.
- `Cmd-b` creates a pane on the right.
- `Cmd-n` creates a pane below.
- `Cmd-w` closes the active pane.
- `Alt-h/j/k/l` moves spatially between panes.
- `Alt-Shift-h/j/k/l` resizes the active pane.

Herdr uses matching Rosé Pine dark and light themes for the tab bar, sidebar,
active borders, and navigation. The tab bar inherits Ghostty's exact black or
white background, while its active tab uses the theme's purple accent. The
sidebar is intentionally compact. At 145
terminal columns or less (approximately half of a full-screen Ghostty window
with the configured font), Herdr switches to its single-column mobile layout
and hides the persistent sidebar. Herdr responds to terminal columns rather
than the physical display percentage, so adjust `mobile_width_threshold` in
`~/.config/herdr/config.toml` if another display or font changes that boundary.

### The agent tab

`Cmd-g` creates or focuses a full-size Codex tab in the current pane's
directory. Repeating the shortcut focuses Codex instead of creating duplicates,
or promotes it out of a split into its own tab.

Before opening it, make sure the shell pane belongs to the correct
project. Give the agent paths and constraints explicitly. For dotfiles or Mac
setup work, say:

```text
Read ~/.config/sync/README.md first and follow its agent contract.
```

### Sessions and recovery

- `Ctrl-Space d` detaches without ending programs.
- `Ctrl-Space w` opens workspace navigation.
- `Ctrl-Space Shift-r` reloads the Herdr configuration after an edit.

Herdr saves workspace, tab, pane, layout, focus, and directory state
automatically. A running server keeps processes alive. After a full server
restart, arbitrary processes become fresh shells; supported agents such as
Codex can resume native conversations when their integration is installed.

Detach when leaving work running. Close individual panes with `Cmd-w`. Avoid
typing `exit` into a pane unless ending that shell or process is intentional.

### Copy mode

Herdr has mouse support and vi-style copy mode. Enter copy mode with
`Cmd-Shift-u`; move with Vim keys, press `Space` to begin a selection, and
press `Enter` to copy it. Press `q` to leave copy mode. The terminal history
limit is 100,000 lines.

### Guided Herdr tour

Try this in a disposable workspace. Start by pressing `Ctrl-Space Shift-n`, enter
`herdr-tour`, and then run:

```fish
printf 'workspace: %s\ntab:       %s\npane:      %s\n' \
    $HERDR_WORKSPACE_ID $HERDR_TAB_ID $HERDR_PANE_ID
herdr workspace list
herdr tab list --workspace $HERDR_WORKSPACE_ID
herdr pane list --workspace $HERDR_WORKSPACE_ID
herdr pane layout --current
herdr agent list
herdr integration status
```

Then exercise the interface:

1. Press `Cmd-t` to add a tab, and `Cmd-h` / `Cmd-l` to switch tabs.
2. Press `Cmd-b` for a right pane and `Cmd-n` for a lower pane.
3. Navigate with `Alt-h/j/k/l` and resize with `Alt-Shift-h/j/k/l`.
4. Press `Cmd-g` twice: the first press creates Codex and the second focuses it.
5. Press `Cmd-Shift-u`, move with Vim keys, select with `Space`, copy with
   `Enter`, and leave with `q`.
6. Press `Ctrl-Space g` for global navigation and `Ctrl-Space ?` for all keys.
7. Press `Ctrl-Space d` to detach. Reopen Ghostty to see it reattach to the
   still-running session.

Use `Cmd-w` to remove the disposable panes and `Ctrl-Space Shift-d` to close the
`herdr-tour` workspace when finished. CLI discovery is always available with
`herdr --help` and, for example, `herdr pane --help`.

## fish and Terminal Fundamentals

Fish is the interactive shell. Commands follow this shape:

```text
program [options] [arguments]
```

Paths matter:

```text
~             home directory
.             current directory
..            parent directory
/             filesystem root
./script      a script in the current directory
```

Quote paths containing spaces: `nano "My Notes/file.md"`. Press `Tab` for
completion, `Up` for history, `Ctrl-r` for searchable history, `Ctrl-c` to
interrupt a running command, and `Ctrl-d` to end an idle shell.

Carapace supplies command completions in interactive Fish shells, including
Ghostty/Herdr and VS Code terminals. It is installed through `packages.txt`
and initialized by `~/.config/fish/config.fish`. Open a new shell after this
configuration changes, or run `carapace _carapace fish | source` in an existing
Fish shell to enable it immediately.

`Tab` opens a compact fzf completion picker using Carapace's suggestions and
descriptions. Type to filter, use the arrow keys to move, and press Enter to
insert the selection; Escape cancels. `Shift-Tab` opens Fish's native completion
menu. `Ctrl-r` opens a matching fzf history picker; Enter places the selected
command on the prompt for review without running it. Both pickers use rounded
borders and the terminal's purple/cyan palette, keeping the current background
and foreground in dark and light terminals. No extra Fish plugin is required.

After changing these widgets, open a new Fish pane, or run
`source ~/.config/fish/config.fish` inside an existing Herdr/VS Code Fish shell.

### Navigation and inspection

```fish
pwd                       # print current directory
z project-name            # jump using zoxide's learned history
cd ..                     # parent directory
l                         # eza listing, including hidden files and Git state
bat file.py                # syntax-highlighted file output
rg 'text'                  # recursively search file contents
rg --files                 # list searchable files
fzf                        # fuzzy-select input paths
open .                     # open current directory in Finder
```

`zoxide` learns directories after you visit them. Use `z foo` rather than
typing a long path. Use `zi` for interactive fuzzy directory selection.

### Filesystem changes

Use Finder or the shell for filesystem changes:

```fish
mkdir -p path/to/folder
touch new-file.txt
cp source destination
mv old-name new-name
rm file
```

`rm` bypasses Trash and is irreversible by default. Inspect paths first;
use Finder or `trash path` when recoverable deletion is appropriate.

### Pipes and redirection

A pipe sends one command's output to another:

```fish
rg 'TODO' | fzf
git log --oneline | head -20
```

Redirection writes output:

```fish
command > file       # replace file
command >> file      # append to file
command 2> errors    # write error stream
```

Do not paste destructive pipelines from an agent without understanding each
stage.

### Processes

```fish
command &                 # start a background job
jobs                      # list shell jobs
fg                        # return latest job to foreground
ps aux | rg program       # find a process
kill PID                  # request process termination
```

Prefer `Ctrl-c` for the foreground process. Do not use `kill -9` unless normal
termination has failed and data loss is acceptable.

## Installed Command-Line Toolkit

### Friendly aliases

```text
l / ls     eza -a --git
cl         clear
py         Homebrew Python (alias for python)
python     stable Homebrew Python command maintained by mac-sync
sv         activate .venv for fish
```

Use `type <name>` to discover whether a name is an executable, function, or
alias. Use `<command> --help`, `man <command>`, or `tldr <command>` when
available.

### ripgrep (`rg`)

```fish
rg 'needle'
rg -n 'needle' src
rg -i 'needle'             # ignore case
rg -g '*.lua' 'setup'
rg --hidden 'needle'
rg --files -g '*.md'
```

ripgrep respects `.gitignore` by default. Prefer it over `grep -R` and `find`
for project searches.

### bat and eza

`bat` is a readable `cat` replacement with syntax highlighting and paging.
`eza` is a readable `ls` replacement. Examples:

```fish
bat ~/.config/fish/config.fish
eza -lah --git
eza --tree --level=2
```

### jq

`jq` reads and transforms JSON:

```fish
jq . file.json
jq '.name' package.json
command-producing-json | jq '.items[] | {name, id}'
```

### Git essentials

Always inspect before changing history:

```fish
git status
git diff
git diff --staged
git log --oneline --decorate --graph -20
git branch --show-current
git switch branch-name
git switch -c new-branch
git add path
git commit -m 'Clear imperative subject'
git pull --ff-only
git push
```

`gcp` stages all changes in a normal repository, asks for a commit message, and
pushes. It is intentionally broad; inspect `git status` and `git diff` first.

Avoid `git reset --hard`, forced pushes, and indiscriminate `git add -A` unless
their exact consequences are understood.

### GitHub CLI (`gh`)

```fish
gh status
gh repo view --web
gh pr status
gh pr view
gh pr checks
gh issue list
```

The GitHub CLI operates on the repository in the current directory. Actions
such as creating PRs, merging, commenting, or closing issues change remote
state; review the target repository and branch first.

### Python through uv

`python` and `py` use the shared Homebrew interpreter for scripts and editor
integrations. Install project libraries with uv so each project's dependencies
stay declared and isolated. Typical commands:

```fish
uv init
uv add package-name
uv add --dev pytest ruff
uv run python script.py
uv run pytest
uv sync
```

`jupyter lab` opens JupyterLab. Create a `uv` project and add the libraries it needs
before using notebooks or Python scripts for that project. C and C++ course
work uses the professor's container rather than shared Mac packages.

Use a project's declared dependencies instead of installing packages globally.

### just: project commands

`just` is a global command runner. A project `justfile` should wrap its existing
tools. This Mac setup's recipes live in `~/.config/mac-setup/justfile`:
`just --justfile ~/.config/mac-setup/justfile check` performs read-only
validation and the `sync` recipe runs `mac-sync --no-pull`. Use that same
`--justfile` argument with `--list` to see recipes. A Python project could use:

```just
check:
    uv run ruff check .
    uv run pyright

test:
    uv run pytest

run:
    uv run python main.py
```

### Jupytext: opt-in notebook pairs

JupyterLab or VS Code can be the notebook UI. Pair only a chosen notebook with
a Python script containing `# %%` cell markers:

```fish
jupytext --set-formats ipynb,py:percent notebook.ipynb
jupytext --paired-paths notebook.ipynb
jupytext --sync notebook.py
```

Edit the `.py` file in VS Code and use Ruff, Pyright, ripgrep, Git diff, or
coding agents on it. Run `jupytext --sync notebook.py` after script edits.
JupyterLab's Jupytext extension maintains explicitly paired files when saving
in the UI. No project-wide pairing rule is set; existing notebooks stay as
they are. `mac-sync` restores the extension after a JupyterLab upgrade.

### VS Code

VS Code is shared through `apps.tsv` alongside the terminal workspace.
Its last tracked configuration before retirement was restored from the parent
of commit `bc45353`, including the existing themes.
The bare dotfiles repository tracks only
`~/Library/Application Support/Code/User/settings.json`, `keybindings.json`,
`tasks.json`,
`~/.config/sync/vscode-extensions.txt`, and `vscode-disabled-extensions.txt`.
`sync-maintain` stages these files;
`mac-sync` installs missing listed extensions on each Mac. Extension binaries,
credentials, workspace storage, logs, and caches stay local.

The extension list retains Python, Pylance, clangd, Ruff, Codex, and the
current Custom UI Style window customization, plus Jupyter for notebooks and
Microsoft C/C++ for its debugger. Microsoft IntelliSense is disabled because
clangd owns C/C++ analysis. Python Debugger and Dev Containers are explicitly
tracked; `vscode-disabled-extensions.txt` removes the optional Python
Environments extension after installation. Built-in AI is disabled,
and Python uses the existing interpreter workflow instead of the experimental
environments integration. Open a project folder with `code path/to/project`;
avoid opening the entire home or iCloud directory as a workspace.

Generated directories and virtual environments are excluded from file watching
and search. Git discovery is limited to open editors without parent repository
scanning. Python reports diagnostics on open files with library indexing off.
clangd runs at most two workers without background project indexing; this
reduces cross-file symbol search until those files are opened. Formatting,
completion, and the restored keybindings remain available.

Markdown files (`.md` and `.markdown`) open as the built-in rendered preview
from Explorer. Use **View: Reopen Editor With... → Text Editor** to edit the
source. Git diffs keep the source text. The tracked CSS-only local extension
`fausto.markdown-preview-wrap` makes preview code blocks, long tokens and tables
wrap as the pane narrows or window zoom increases. Its source lives under
`~/.config/sync/vscode-markdown-preview-wrap`; `install-vscode-local.py`
packages and installs it on each Mac during `mac-sync`. Reload an open VS Code
window after first installation. This uses the preview's supported extension
style contribution so the stylesheet is within its allowed resource roots;
a user stylesheet outside the workspace is blocked. Generated VSIX files and
installed extension folders remain local.

The Fish login terminal uses the existing prompt, aliases and toolchain PATH;
Herdr only starts automatically in Ghostty, so it does not nest inside VS Code.
Terminal splits inherit the current directory and persistent sessions are
explicitly enabled. VS Code uses standard editing motions without Vim emulation.
Python defaults to the project `.venv` for newly opened workspaces; an already
selected interpreter must be changed with **Python: Select Interpreter**.

VS Code's clangd uses the `amsc-clangd.sh` bridge. Open
`~/shared-folder` or one of its project subdirectories in its own VS Code
window. For these folders the bridge runs Linux clangd in the running AMSC
container, maps file paths, loads GCC 11.2 and queries its system headers.
Outside this tree it uses native macOS clangd. If the container is stopped,
the bridge reports how to start it rather than producing misleading Mac
compiler diagnostics for Linux code. VS Code's two-worker/no-background-index
arguments are forwarded.

For direct access to Linux headers, use **Dev Containers: Attach to Running
Container... → amsc**. The tracked `~/.config/mac-setup/vscode-amsc.json` is
merged into the local named-container configuration by `vscode-amsc.py` during
sync. It opens `/shared-folder` as `ubuntu`, installs Linux clangd/C++
extensions, uses the course Bash startup, and runs clangd with the same GCC
module environment. Container state, server files and extension binaries stay
local. OrbStack remains the required local Linux runtime; Dev Containers
connects to it and does not replace it. A new container needs the helper
restored with `mac-sync --no-pull` after it is started.

The header discovery includes installed AMSC libraries, not the module state
of an unrelated interactive shell. Run library-specific `module load` commands
in the terminal before builds; use a project `compile_commands.json` for exact
macros, compiler flags and include paths. For CMake, configure inside the
container with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, then point the project
clangd config at that build directory. Do not compile the Linux course library
stack with macOS clang.

On Apple Silicon, this Intel course image cannot use GDB's normal local
`run` command. The verified alternative is Rosetta's remote debug server:

```sh
# In the AMSC terminal, after loading GCC and the project's library modules:
ROSETTA_DEBUGSERVER_PORT=54329 /absolute/linux/path/to/executable
```

Build with `-g` for debug symbols. In the attached VS Code window, select
**AMSC: connect to Rosetta debug server** in Run and Debug, and enter that same
Linux executable path. The tracked launch template is also available at
`~/.config/mac-setup/vscode-amsc-launch.json` for a project's `.vscode/launch.json`.
Direct GDB failed with a register error; the remote connection successfully
stopped at `main` and inspected `argc`. No runtime restart or security-setting
changes were needed.

For Python notebooks, use your uv project environment:

```sh
uv sync
uv add --dev ipykernel
```

Select the project's `.venv/bin/python` as both Python interpreter and notebook
kernel. The kernel selection is independent of the editor's interpreter. Use
`uv add` for dependencies so `pyproject.toml` and `uv.lock` stay authoritative.
**Tasks: Run Task** offers uv sync, run-current-file, pytest and Ruff check.
These tasks only run when invoked; pytest/Ruff must be available in the project
or command environment. Test discovery on save is disabled; configure the
project's test framework when needed and run discovery/tests manually.

PDF files open inside VS Code using the Marketplace extension PDF Preview Dark.
Its default colour scheme follows the VS Code theme, which follows macOS
appearance. The toolbar can restore original colours when needed; dark rendering
also changes embedded images. Remote PDFs are supported. Sync installs the
viewer and removes the retired `fausto.preview-pdf` external opener. Reload
VS Code if asked after extension changes.

Useful built-in tools for reviewing generated code are notebook diffs, Variable
Explorer/Data Viewer, the Problems panel, tests, debugger watches, selective Git
staging and separate Git worktrees for concurrent agent changes. Extra Lua/TOML
extensions are not priorities for the current Python/C++ workload. Herdr's agent/worktree management remains available in the terminal.

#### Terminal tools and optional editor companions

Keep the shared extension list focused on the active Python/C++ workflow.
The terminal tools do not each need their own editor extension:

| Terminal tools | Existing VS Code companion |
| --- | --- |
| Fish, Pure, zoxide, fzf | Fish terminal with the existing prompt and shell integration; Quick Open for editor files |
| ripgrep, fd, eza, bat | Search, Explorer and source editors |
| uv, Ruff, Python, Jupyter | Tracked Python/Ruff/Jupyter extensions and manually invoked uv tasks |
| Git, delta, gh | Built-in source control and visual diffs; keep `gh` for GitHub operations |
| just | Invoke project recipes in the terminal or define an explicit project task |
| btop | Keep system monitoring in the terminal |

This optional extension is not installed by the shared manifest:

- [Jupytext Sync](https://marketplace.visualstudio.com/items?itemName=caenrigen.jupytext-sync)
  (`caenrigen.jupytext-sync`) keeps explicitly paired notebooks and `.py`
  files synchronized on save. This is useful when Codex edits the text version
  while the notebook UI shows outputs. It needs Jupytext in the Python
  environment it selects. The existing CLI workflow remains sufficient for
  manual sync; the Jupyter extension already runs `# %%` Python cells.

Documentation verified through Context7 `/microsoft/vscode-docs` and
`/websites/astral_sh_uv`, plus [uv notebooks](https://docs.astral.sh/uv/guides/integration/jupyter/)
and [OrbStack debugging](https://docs.orbstack.dev/machines/#debugging-with-gdb-lldb).

To diagnose a recurring spike, run `code --status` while it happens and use
**Developer: Open Process Explorer** to identify the busy process. If the
extension host is responsible, run **Help: Start Extension Bisect**. Test with
the actual project before concluding that a previous CPU issue is resolved.

### Codex

The current entry point is T3 Code. Select the project and workspace there
before starting a Codex thread. The terminal CLI remains installed as T3's
provider backend and for configuration diagnostics.

Provide concrete requests: desired outcome, relevant files, constraints, and
verification. Ask the agent to inspect before editing when the problem is not
yet understood.

## Common Workflows

### Begin work on a project

```fish
z project-name
git status
code .
```

Use `Cmd-g` in Herdr to open the agent tab when useful.

### Inspect a change before committing

```fish
git status
git diff
git diff --check
```

Run the project's tests, stage intentional paths, inspect `git diff --staged`,
then commit.

### Recover the workspace

Reopen Ghostty; it attaches to the persistent Herdr session. After a machine or
server restart, Herdr recreates the saved layout and working directories and
resumes supported agent conversations when integrations are available.

### Edit this setup

Use `code ~/.config` and run `keymap-docs` and `keymap-docs --check` after
keymap changes. Reload Herdr with `Ctrl-Space Shift-r` after its configuration
changes.

## Mac Synchronization

### Routine command bundles and startup audit (2026-11-11)

The user-facing command family is `mac status`, `mac sync`, `mac save`, and
`mac update`; the root `~/README.md` has the occasion-to-command table.
`mac sync` rejects dirty/staged dotfiles, fast-forwards once, then applies the
checkout. `mac save` reuses `bcp` (capture, apply, keymap validation, staging,
commit and push); it stages maintained configuration broadly, so review
unfinished edits first. `mac update` calls the existing updater with `--now`.
`bare` remains a plain Git alias, and lower-level commands remain available
for diagnosis. Git pull errors stop the canonical bundle before application.

All four bundles end with a separate action panel and keep the latest full
transcript, including that panel, under `~/Library/Logs/mac-routines/`.
`manual-actions.py` repeats detectable missing web apps/TwitchNoSub, pending or
unapplied extension choices, failed updates and installers needing interaction.
Existing `bcp`, `mac-sync`, and direct maintenance also print the action list
when they reach their reporting step; the canonical bundles print it even
when an earlier step fails. Logs, manifests and credentials remain local except
for explicitly shared metadata. A successful exit does not erase manual tasks.

Pro audit: no crontab; the login/hourly shortcut-data/check agent is loaded and
last exited 0. The 30-minute app updater is loaded; its last pass recorded five
fetch failures and five pending updates. A same-environment Raycast fetch
subsequently succeeded; this does not establish that the other downloads or
the next scheduled pass succeed. Hammerspoon's login opener is loaded and
exited 0. The root awake/remote recovery job is loaded but idle; Office licensing
and OrbStack helpers are on demand. No extension timer is added, and the
existing automatic job boundaries remain unchanged.

Herdr's original Homebrew login service had attempted over 2,400 duplicate
starts while the user's independently launched server remained healthy.
`herdr-service.py` now reconciles that same label with a wrapper that exits
successfully if a server already exists, and supervises a server it starts.
A successful no-op is not restarted. A later manually started server is not
monitored by this completed job; opening Herdr starts it again if needed.
The active server and sessions were preserved. Do not run `brew services start
herdr` separately; manual sync installs/reconciles its login configuration.

The background-items inventory additionally shows enabled Raycast, Task Timer,
Wispr Flow and Karabiner items, app-owned background tasks and native updaters.
GoogleUpdater's hourly plist is not loaded and is disallowed; its two empty
Keystone plist placeholders are inert. Retired OmniWM/Vorssaint registrations
remain in background-item metadata; an entry is not evidence of a live
process or installed app. These were not reset wholesale. The exact current
loaded plist inventory is available with `mac status`; System Settings >
General > Login Items & Extensions also includes modern app registrations.
Fish startup initializes PATH, Pure/Carapace/fzf/zoxide and OrbStack shell
integration; Ghostty attaches to Herdr. It does not start sync or upgrades.

### Helium extension choices

`helium-extension add/remove ID` records a timestamped install/removal event,
exchanges it immediately with the separate `helium-extensions` data branch in
the private Dotfiles remote, and applies macOS managed policy locally. A Chrome
Web Store URL is accepted by add/remove; `--name` supplies an optional display
name. `helium-extension list` is local inspection only. Manual `mac-sync`, and
therefore both sync/save bundles, exchange and apply the list. Scheduled/check
runs never do so and never request administrator authorization.

Initial enrollment imports this Mac's installed store extensions once and fills
gaps in the shared set. Existing shared choices, including deletions, take
precedence over initial imports. Subsequent choices must use add/remove;
normal UI changes are not silently timestamped at scan time. Unshared UI
installs are reported by `list`. The later command timestamp wins per ID;
independent changes merge. Mac clocks must be correct; a stable device ID
breaks equal-time ties, and a local logical clock prevents backward revisions.
Offline edits are saved before network access, retried without force-pushing,
and never change the working dotfiles index/HEAD. Keep the local state under
`~/Library/Application Support/mac-sync/helium-extensions/` so commands retain
their identity and pending edits.

Only IDs, display names, timestamps and removal events leave this Mac.
Browser preferences, cookies, credentials, profile databases, extension code,
extension settings, pinning and enabled/disabled choices are not transferred.
TwitchNoSub is an explicitly user-approved manual-install exception; its
missing installation is highlighted at the end of routine bundles. Built-in
extensions, themes, PWAs, bookmarks and Dock layout are outside this sync.

Policy uses bare IDs in `ExtensionInstallForcelist`, so Helium selects its own
store/proxy URL. Explicit standard Chrome URLs were rejected in the live test
by Helium's inherited unmanaged-Mac policy filter; that unsuccessful approach
was replaced. Explicit removals use `ExtensionSettings` with `removed`.
The helper merges only the managed IDs into the root-owned
`/Library/Managed Preferences/net.imput.helium.plist`, preserving other policy
keys and per-extension fields. Changed policy requires ordinary sudo; no
passwordless rule or resident privileged helper is installed. Helium may need
its native policy refresh (`helium://policy`, Reload policies) or a relaunch,
and downloads can take longer. Managed extensions cannot be removed from the
normal UI; use the command. A policy write alone does not prove installation.


The MacBook Air, MacBook Pro, and Mac Studio use one shared app manifest. Apps
are shared by default; formulae are shared only when intentionally listed in
`~/.config/mac-setup/packages.txt`. Run an immediate reconciliation with:

```fish
mac-sync
```

`~/.config/sync/install-agent.sh` also supports installation over SSH without
a desktop login. It loads the hourly agent in the background user domain when
no GUI domain exists. Initial sync errors are reported without disabling the
agent; administrator authorization or App Store sign-in may still be needed.
Missing App Store apps are deferred without failing the manual sync when no
desktop session is logged in, rather than launching `mas` and waiting indefinitely. Log in to the
Mac's desktop and App Store, then rerun `mac-sync` to finish those installs.
App retirement over SSH moves intact bundles into unique
`~/.Trash/mac-sync-retired.*` folders without Finder. If permissions require
administrator rights it uses only cached authorization (`sudo -v` beforehand);
scheduled runs never prompt. The log reports the recovery path.

An existing app bundle in `/Applications` or `~/Applications` satisfies its
manifest entry even when installed outside Homebrew. Sync leaves its ownership
and built-in updater alone; it does not adopt or reinstall it just to create a
cask record. Quitting an app is not needed for these installation checks.
Formula checks use one installed Homebrew inventory, including aliases, and
install only missing packages. Already protected packages are not rewritten.
The nuke step reuses that same inventory, preserves shared aliases, and also
removes orphaned dependencies when there are no temporary top-level formulae.

To see which part takes time on either Mac, run:

```fish
mac-sync --timing
```

This reports seconds for shortcuts/dotfiles, Homebrew, container configuration,
retirement, apps, editor settings, and the total. `--quiet --timing` keeps these
timings visible while suppressing routine progress. Downloads for genuinely
missing software and network synchronization can still take time.

Install an experimental formula normally with `brew install`; it remains local
and temporary. Add only frequently used or current-project formulae to
`packages.txt`, one formula name per line (for example, `carapace`, without
`brew install`). Run `mac-sync --no-pull` to install it on this Mac, then use
`bcp` to commit and push the manifest so the other Mac receives it at its next
sync. A plain `brew install carapace` installs it only on the current Mac.

To remove every temporary top-level formula and any dependency that is no
longer needed, run:

```fish
mac-sync --nuke
```

The C/C++ formulae and shared scientific Python libraries are retired in
`retired-apps.tsv`. `mac-sync` removes them when no remaining shared formula
requires them. The professor's container supplies the C/C++ environment;
Python project dependencies belong in `uv` environments. Ruff, Pyright,
JupyterLab, Jupytext, and the Homebrew Python interpreter remain available.

The nuke operation does not touch casks or App Store applications. Use
`mac-app` for applications: shared is the default, `local` records an app for
one Mac, and `temporary` installs it without recording it.

Install and share an app with one command. Homebrew casks are the default:

```fish
mac-app firefox
mac-app share --mas 497799835 Xcode
mac-app local transmission
mac-app skip firefox
mac-app unskip firefox
mac-app remove firefox
mac-app remove --mas 497799835
```

`mac-app` records, commits, and pushes app changes. A LaunchAgent exchanges
menu-shortcut data and checks local manifests at login and hourly; it never
pulls executable configuration, installs software, or removes retired data. Per-Mac app lists and skip lists live under
`~/.config/mac-setup/machines/`. Direct downloads require a checksum-pinned
installer under `direct/`. `mac-app remove` takes a shared app identifier,
removes its row from `apps.tsv`, records the exact row in `retired-apps.tsv`,
and runs `mac-sync` locally. Run `mac-sync` manually on the other Mac to apply
the removal there. Scheduled checks do not apply retirements. Ordinary manifest
edits do not uninstall software. Sharing or locally installing a retired app
again clears its retirement entry.

### Engineering apps and reviewing Mac differences

Keep the engineering tools on the MacBook Pro using its local app manifest:

```fish
mac-app local paraview ParaView
mac-app local blender Blender
mac-app local qgis QGIS
brew tap tangency-labs/tap
brew trust --cask tangency-labs/tap/solidcraft
mac-app local tangency-labs/tap/solidcraft SolidCraft
mac-app local --direct openfoam2306 "OpenFOAM v2306"
```

Blender, QGIS, OpenCFD OpenFOAM, and SolidCraft are free and open source;
none requires a Polimi account or a student licence. SolidCraft's official
tap needs trust for that cask only. All four entries belong exclusively to
`machines/fausto-s-macbook-pro.tsv`, never `apps.tsv` or the Air's manifest.

OpenFOAM uses the existing OrbStack engine, not a Homebrew formula. Its
reviewed `direct/openfoam2306.sh` installer creates `~/.local/bin/openfoam2306`
and pins the official `opencfd/openfoam-default` Linux arm64 image to
`sha256:7df8c49ff2f966deb0d8afba54a5deb19befc93ea4346e974f0f13869572c289`.
Start OrbStack manually before using the launcher. It mounts the current directory at
`/home/openfoam`, and runs as the current Mac UID/GID so results remain owned
by the user. Containers are disposable; case files stay in that directory.
Maintenance only restores the launcher; it never probes OrbStack or checks or
pulls container images. Running the launcher uses Docker directly, which pulls
the pinned image if absent and reports an error if the engine is stopped.
The official entrypoint runs under Bash to preserve its profile's temporary
arguments; Ubuntu's `/bin/sh` otherwise executes `bash -c` commands twice,
including once before all solver libraries are configured.

Run `openfoam2306` for an interactive shell, `openfoam2306 -build-info` for
the exact release, or `openfoam2306 snappyHexMesh -help`. A small solver check
in a new case directory is reproducible with:

```fish
mkdir -p ~/Documents/OpenFOAM/cavity-check
cd ~/Documents/OpenFOAM/cavity-check
openfoam2306 -c 'cp -r "$FOAM_TUTORIALS/incompressible/icoFoam/cavity/cavity/." . && blockMesh && icoFoam && checkMesh'
```

The 2026-10-30 installation verified OpenCFD API 2306, patch 0, build
`_fbf00d6b-20230626`, `snappyHexMesh`, and the 400-cell cavity through time
0.5 with `Mesh OK`. A case path containing spaces, user-owned persistent
output, piped stdin, and propagation of exit status 37 also passed. These are
installation checks, not validation of a project simulation. Blender 5.2.3 LTS
loaded its default eight-vertex cube in background mode; SolidCraft's official
tap installed 0.27.1 (newer than the website's displayed 0.22.0).
One retry immediately after deleting and recreating the same bind directory
failed during file copying; the final solver check used a fresh directory.
QGIS 4.2.3 opened, created a valid EPSG:4326 memory layer, and transformed
(9, 45) to UTM 32N (500000, 4982950.4002). Bare bundled CLI/Python calls warn
about PROJ data before QGIS initialization; for CLI use, prefix the command
with `PROJ_DATA=/Applications/QGIS-final-4_2_3.app/Contents/Resources/qgis/proj`.
The initialized QGIS transform passed without that override. Its DMG matched
Homebrew's SHA-256 after the slow selected mirror was replaced by `dl1.qgis.org`.
All 24 existing sync tests and the other `just check` validations passed;
`mac-sync --no-pull --timing` completed in seven seconds with all four entries.

Fusion was subsequently removed with its supplied `Remove Autodesk Fusion`
app in normal uninstall mode (`--silent --quiet`); `--purge-incomplete` only
cleans partial installs and does not remove a complete installation. Remaining
Autodesk support files, preferences, caches, HTTP/WebKit data, temporary IPC
files, and the `AdskIdentityManager` keychain key were removed separately.
macOS retained six empty `com.apple.WebKit.*+com.autodesk.*` directories in
the user's temporary directory: their `sunlnk` flags prevented removal even
with administrator privileges. Fusion's entry is removed from the Pro's app
manifest so sync cannot reinstall it. Browser website sessions and online
Autodesk account data are separate from the removed application.

Review `~/.config/mac-setup/machines/*.tsv` and `*.skip` for intentional app
differences. These describe intended installations, not a live inventory of
the other Mac. `brew list --formula --installed-on-request` lists explicitly
installed formulae to compare with `packages.txt`; resolve aliases such as
`python` with `brew info` and retain dependencies still required by shared
tools. Use `brew uses --installed <formula>` to inspect dependents. Review
unlisted cask receipts with `brew list --cask`; a renamed or self-updated app
can satisfy a manifest while retaining an older cask token. Ordinary sync
does not remove these extras. Existing uncommitted dotfile edits prevent
automatic pulls, so local manifest edits are not evidence of the Air's setup.

The 2026-10-30 review kept Affinity, Autodesk Fusion, DaVinci Resolve, UTM,
and ParaView local to the Pro; the Air's local list was empty. Fusion
2706.1.17 was installed manually and its installer moved to Trash. CodexBar
was repaired to 0.82.0, launched successfully, and its interrupted upgrade
backup removed while retaining settings. Unused `libomp` and the older
`t3-code` receipt were removed, keeping T3 Nightly. `python@3.14` remains a
Jupytext dependency, not an explicit installation.

ParaView's first transfer was slow. A manual resume overlapped with hourly
sync, so the uncontended prefix was recovered and the transfer restarted in
`~/Library/Caches/ParaView-6.2.0-arm64.dmg.partial`, outside Homebrew's cache.
For future manual resumes, keep incomplete downloads outside that cache and
add the app manifest entry only after download and checksum verification;
otherwise scheduled sync may start a competing writer. Progress and final
verification are logged to `~/Library/Logs/paraview-install.log`.
The recovered download matched Homebrew's SHA-256 and installed ParaView
6.2.0 for arm64. Its bundled `pvpython --no-mpi` processed a Wavelet source
(9,261 points, 8,000 cells) and exposed `OpenFOAMReader`; no OpenFOAM solver
was installed. All 24 sync tests and the remaining `just check` validations
passed, and maintenance completed successfully with Homebrew Python.

The removed `jj` configuration and custom skills are no longer required by
the maintenance staging script. Maintenance now sets the same Homebrew-first
PATH as `mac-sync`, avoiding Apple's older Python for helpers using `tomllib`.

MuPDF, Highlights, Negative, and Sioyek are retired on every Mac. The
idempotent cleanup built into `mac-sync` removes their app bundles,
formula/cask installations, appearance automation, and app-specific user data.
It preserves PDF documents. macOS privacy restrictions may require granting
Full Disk Access to the terminal running `mac-sync` to remove sandbox data.
For administrator-owned app bundles, run `sudo -v` before `mac-sync`.

Pi Desktop, the Pi coding agent, and Zed are retired on every Mac.
`mac-sync` permanently removes their apps, Pi npm packages, settings, MCP
configuration, credentials, extensions, sessions, logs, and app caches.

`retired-apps.tsv` also records explicit removals. ChatGPT is retired on each
Mac; VS Code is shared. Neovim, VS Code Vim, the Lua language server and
Tree-sitter CLI were retired on 2026-11-03. The retirement manifest removes
the formulae on sync; installed Neovim plugins and caches can be moved to Trash.

`sync-maintain` runs the same convergence check, regenerates keymap docs, and
stages maintained dotfile paths. Tracked sync helpers are staged together with
`git add -u`; new helper files require an explicit add so local scratch files
stay local. The old empty inventory/state directory layout is no longer used.
The Markdown preview extension source is explicitly included in maintenance
staging. `bcp` then asks for a commit message when changes are staged and pushes.
It stops on maintenance, staging, diff or commit failures; a clean tree skips
the commit prompt and still retries a previously failed push. Push/report
failures return a nonzero status. `bcp` is manual; only `mac-sync` runs at login
and hourly. Scheduled runs exchange only menu-shortcut data and check local
application/package drift; incoming code and setup changes require manual
`mac-sync --pull`. A plain `mac-sync` applies the current local checkout. Run `source ~/.config/fish/config.fish`
in existing Fish shells to load updated function definitions.

Verification on Pro (2026-11-02): `just --justfile ~/.config/mac-setup/justfile
check` passed 62 tests plus configuration checks, and `sync-maintain` completed.
The new tests use temporary Git history to cover bcp failures and clean-tree
push retries, and verify VSIX contents, unchanged-install skips, CSS updates
and install failure propagation. Remote deployment remains unverified.

Validation (2026-11-11, Pro): the complete `just check` recipe passed using
Homebrew's Python-first PATH; Apple's Python cannot run the existing tomllib
checks. The focused tests cover reverse-order publication, offline merges,
bootstrap deletion protection, monotonic/tied revisions, policy preservation,
manual-action persistence, command boundaries and full failure transcripts.
A disposable Helium 0.21.1.1 / Chromium 157.0.8103.38 profile recognized the
ID-only force list with status OK and installed all 12 shared store extensions
through Helium's own proxy. Early 12-second checks were incomplete; later
bounded checks observed 7 and then 12 installations. Live uninstall was not
run against the user's profile; explicit removal policy generation is tested
in isolated fixtures. Herdr's duplicate-start job settled at one successful
run, preserving its original server. A dirty `mac sync` failed before pulling
and saved its action panel/transcript. No remote Mac rollout is verified:
Pro's Tailscale is stopped, Studio's canonical hostname could not resolve,
and Air's LAN hostname could not resolve. Pro's VPN state was preserved.
A subsequent full local sync reached the final check in 26 seconds but failed
because another session added five window bindings without regenerating their
keymap table. Those unrelated, unfinished changes were preserved.
Reproduce with `PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH
just --justfile ~/.config/mac-setup/justfile check`, `mac status`, and
`helium-extension list`. Use `mac sync` on other Macs once reachable; the
first changed-policy application needs their administrator authorization.

Final reconciliation (2026-11-11): the compact workflow-guide commit and the
concurrent display-control work were merged without losing either workflow;
unrelated working edits were preserved. The complete recipe passes 149 tests. Manual application completed successfully in
11 seconds. Its remaining action list correctly reports the earlier updater
failures, three interactive installers and three missing web apps. A pre-existing
retirement bug also surfaced: macOS reads OmniWM's empty plist as `{}` but
`defaults delete` returns “domain not found.” Cleanup now removes the empty
retired file directly; missing preferences are already clean, while failures
to delete real preferences still propagate. The added regression case covers
all three conditions. Air and Studio remain unreachable; their rollout is pending.

### Helium web apps

`~/.config/sync/helium-apps.json` shares Helium web-app names and HTTPS launch
URLs. It includes Gmail, Slack, SoundCloud, WeBeep, WhatsApp Web, Telegram Web,
Discord, and Messenger. App bundles, browser registrations, and sign-ins stay local.

Install web apps normally in Helium, then run `bcp` to capture, commit, and push
their names and URLs. `sync-maintain` also captures and stages this list when
run on its own. Capture adds apps and updates names; an app missing on one Mac
never deletes it from the shared list.

The other Mac receives the shared list after a reviewed manual
`mac-sync --pull`. At the very end of `mac-sync` or `bcp`, each
missing app gets a reminder in this exact format:

```text
INSTALL Gmail WEB APP
```

Open the app's URL from `helium-apps.json` in Helium and install it as a web
app yourself. On the next run, its reminder disappears. Installed apps are
matched by launch URL, so a different local app name does not cause a reminder.
Apps installed in other browsers do not count as Helium apps. When nothing is
missing, no web-app reminder is printed. Reminders remain visible with
`mac-sync --quiet`; scheduled runs write them to `~/Library/Logs/mac-sync.log`.
`sync-maintain` run directly also ends with these reminders; nested maintenance
inside `bcp` defers them until after the commit and push to avoid duplicates.

Keep `~/.config/sync/helium-apps.py`: maintenance uses `capture` and the final
reminders use `report`. There is no setup step, configuration profile, automatic
web-app installation, or automatic web-app removal.

On 2026-11-05, Beeper Desktop was uninstalled from Air, Pro, and Studio and
added to `retired-apps.tsv`; remaining local Beeper data was moved to Trash.
The four messaging apps were installed in each Mac's own Helium profile using
its built-in `PWA.install` / `chrome.management.generateAppForLink` APIs and
set to standalone windows with `PWA.changeAppUserSettings`. Signatures, native
registrations, normal local profile paths and Beeper absence were checked;
all 11 existing web-app sync tests passed on each Mac. Pro required the
one-time installer in its GUI launchd context after SSH keychain access failed.
Air's Beeper login item was removed; remote login-item cleanup on Pro timed
out, so its stale startup-entry removal is unverified. Browser state and
credentials were not transferred. This was a one-time installation;
`mac-sync` continues to share URLs and report missing web apps.

### macOS App Shortcuts

Edit shortcuts normally in System Settings > Keyboard > Keyboard Shortcuts >
App Shortcuts, including All Applications. `mac-sync` captures additions,
changes, and removals on either Mac at login and hourly. Run `mac-sync` on each
Mac for an immediate exchange. An offline Mac keeps its edits for the next
successful sync. Apps may need reopening to refresh their menu shortcuts;
reopen System Settings if its list was already open during sync.

`~/.config/sync/app-shortcuts.py` synchronizes only `NSUserKeyEquivalents` and
the App Shortcuts application list. Other Keyboard Shortcuts categories,
modifier keys, keyboard hardware settings, and Services remain local.
The seed contains the existing Helium and Preview shortcuts and is used only
when creating the shared data branch; subsequent removals are preserved.
The old one-way Helium plist enforcement has been removed.

If macOS refuses changes to `com.apple.universalaccess`, enable the terminal
running `bcp` (for example Ghostty) in System Settings > Privacy & Security >
Full Disk Access, quit and reopen the terminal, then rerun `bcp`. macOS protects
the App Shortcuts application list separately from the shortcut values. The
sync retains local state and reports failure until that list can be updated.

Shortcut data is committed and pushed automatically to the separate
`app-shortcuts` branch in the existing private Dotfiles repository. Its only
file is `shortcuts.json`; this operation never stages or pushes the working
dotfiles branch. `~/Library/Application Support/mac-sync/app-shortcuts/`
holds a local baseline, pending edits, and an independent bare Git transport.
Keep this local state: it distinguishes an intentional deletion from a Mac
that has not received a shortcut yet. A newly enrolled Mac imports its local
shortcuts, while existing shared entries and deletions take precedence.
Creating a file named `paused` in that local directory pauses shortcut sync
on that Mac; removing it resumes sync.

Independent menu edits merge. For competing edits to the same application and
menu title, the later captured edit wins (using timestamps and a stable device
ID to break ties). Deletions remain recorded so a stale or newly enrolled Mac
cannot bring them back. Concurrent pushes retry without force-pushing. Network
failures retain pending edits and leave local shortcuts unchanged. The two
Macs converge once each has completed a successful sync; this is hourly sync,
not an immediate live connection.

### Portable app settings

`~/.config/sync/app-preferences.json` shares a reviewed whitelist of interface,
behavior, and performance preferences for installed apps in the shared app
manifest. Local-only apps are excluded. `app-preferences.py apply` runs during
`mac-sync`; `capture` runs before reconciliation during `sync-maintain` so
changes made in the apps can be staged. Publish those changes with `bcp` from
any Mac; the other Macs apply them during their next sync. There is no master
Mac. Unpublished changes do not automatically propagate.
Run `bcp` after changing a shared preference; apply reviewed incoming values
on other Macs with `mac-sync --pull`. Fausto selected Raycast, T3 and Tailscale (Dock visibility
only); CodexBar keeps its existing enabled profile. QuickRecorder, MacWhisper
and OrbStack preference sharing remain off.

Choose portable preference sharing per app, independently of its installation:

```sh
python3 ~/.config/sync/app-preferences.py list
python3 ~/.config/sync/app-preferences.py enable Raycast
python3 ~/.config/sync/app-preferences.py disable Raycast
bcp
```

Disabling leaves each Mac's current settings intact. These controls apply to
the reviewed preference profiles below; existing tracked configuration files
continue to use the dotfiles workflow. Apps may need reopening to load changed
preferences. T3 interface settings are merged only while T3 is closed; an open
app defers them until a later sync. Browser connections and other local fields
in its settings file are retained.

The 24 published shared app entries were reviewed on 2026-11-01:

| Shared app | Settings route and current coverage |
| --- | --- |
| Ghostty, Karabiner-Elements, Visual Studio Code | Existing tracked configuration; VS Code's selected extensions are installed during sync. |
| Codex | Existing reviewed plugin choices and public MCP endpoints; account connections stay local. |
| CodexBar | Portable refresh/power settings and selected provider fields; credentials retained locally. |
| QuickRecorder | Encoder, HDR/audio choices, mouse/background and menu/Dock visibility. Recording areas, microphones and save locations stay local. |
| MacWhisper | App visibility, playback-window behavior and completion sound. Models, recordings, transcripts, microphones and AI credentials stay local. |
| Raycast | Selected general interface/navigation preferences. Extensions, aliases and command hotkeys need its native export or optional [Pro Cloud Sync](https://manual.raycast.com/cloud-sync). No subscription or cloud-data upload was enabled. |
| T3 Code (Nightly) | Selected interface, notification, confirmation, diff and sidebar preferences. Conversations, projects, connections, browser profiles, models and credentials stay local. |
| OrbStack | Menu-bar visibility. VM/container data, CPU/RAM limits, networking and device-specific settings stay local. |
| Tailscale | Dock visibility only. Device identity, routes, exit nodes and connections stay local. |
| Helium | Menu shortcuts, command-driven store-extension choices and manual-action web-app reminders. Browser profiles, sessions and history stay local. |
| Wispr Flow | Its [account sync](https://docs.wisprflow.ai/articles/5284722493-sync-flow-across-your-devices) handles supported dictionary, snippet, language and style preferences. Shortcuts, microphones and sounds are per-device. |
| Anki | Use [AnkiWeb](https://docs.ankiweb.net/manual/syncing) for collections. This is not a full application-preferences sync; local databases are not copied. |
| WhatsApp Web, Telegram Web, Discord, Messenger | Helium web apps; sign in separately on each Mac. Beeper Desktop is retired. |
| Microsoft Excel, ProtonVPN | No reviewed portable settings profile yet. Sandboxed/account data and VPN state are excluded. |
| MySielteID, Solves | No reviewed portable settings interface verified in this audit; app-specific setup remains manual. |
| GitHub Copilot CLI | Only a first-launch timestamp was present in its config; nothing portable was selected. |
| SF Mono | Shared font installation; no separate application preferences. |
| Hammerspoon | Tracked one-desktop maximize/split configuration; Accessibility authorization stays local. |

The Air is the minimal Mac: it uses the common shared app list without local
extras. Every explicit shared-app uninstall from the Pro or Studio must reach
the Air through retired-apps.tsv and mac-sync, including MagHue. Retirement
entries remain published so later syncs cannot reinstall removed apps. The Pro
and Studio keep their independent machine-specific extras. Choose `mac-app share` or `mac-app local`
from the Mac where an app is being added. Managed installs on the Air always
join the common set, including requests for local/temporary installs. Sharing
a formerly local app removes its duplicate rows from machine manifests.
`local` is for extra apps and refuses an already shared app; `skip` excludes a
shared app on one Mac. Do not promote heavy tools into the common list merely
to match the Studio to the Pro. Apps installed outside `mac-app` are not
automatically enrolled.

Full application plists and databases stay local.
The portable Qalculate numeric/formatting preferences in
`~/.config/qalculate/qalc.cfg` are tracked; calculation histories stay local.

Obsidian, Spotify, Vorssaint, and MagHue are retired on every synced Mac. Their named
application data and caches are removed during manual sync; privileged helpers need
administrator authorization (`sudo -v` before `mac-sync`). Scheduled checks
never remove apps or invoke privileged helpers. Obsidian
retirement removes app state only; note vaults remain user documents.
Same-named Safari web apps are preserved and do not block native-app data
cleanup; Spotify's Safari wrapper is a separate lightweight installation.

ChatGPT retirement uses normal cask uninstall plus named ChatGPT paths, never
Homebrew's broad zap list, which includes Codex/CUAService data. During Studio
enrollment the older rule moved 12 such objects to Trash; all 12 were restored
in place without overwriting files, and a regression test now preserves them.

CodexBar uses adaptive refresh and
follows system Low Power Mode. Its provider IDs, enabled choices and selected
source are shared through the whitelist, merged into
`~/.config/codexbar/config.json` while preserving local credentials. Provider
catalog order is retained during capture; unknown providers and
machine-local file/account source references are not automatically enrolled.
The former tracked `~/.codexbar/config.json` was an inactive duplicate and has
been removed.

Ghostty uses a non-blinking default cursor and keeps vsync enabled.

`python3 ~/.config/mac-setup/cleanup-orphan-app-data.py --delete` removes only a reviewed,
explicitly approved list of obsolete app-data folders after checking app bundles,
executables and running processes. Existing installations keep their data.
Discord, GitButler and Tor Browser also require their retirement entries.
This never removes project or document directories. macOS Full Disk Access may
be needed for protected folders. Without `--delete`, the script archives data
locally for review instead of permanently deleting it.

Closed-app background policy (2026-11-02): preserve normal background work
while an app is open, including CodexBar polling and Wispr dictation. Their
startup behavior stays unchanged. The same cleanup script, called by
manual `mac-sync`, sends SIGTERM to reviewed orphaned Beeper Contacts
and crash-report helpers, Wispr's native companion/crash reporter, and Helium
or VS Code crash reporters only after their main app is absent. It checks the
current user, exact executable, parent PID 1 and app state again before acting.
No new watcher runs; leftovers can remain until the next sync. App data is
preserved and live-app helpers are skipped. Five isolated safety tests cover
ownership, active apps, process reuse, relaunch, dry runs and inspection failure.
Pro's stale Vorssaint login item was removed; Beeper's login launch is retained.
Three dry-run measurements of `cleanup_closed_app_helpers(dry_run=True)` on
Pro took 24–29 ms wall time and 24–28 ms Python/child CPU time. This adds no
timer, resident process, sleep assertion or scheduled wake. Battery impact
has not been measured directly; the existing sync schedule is unchanged.

### Codex technical setup

Codex is used through T3 Code. `~/.config/sync/codex-technical.json` tracks
shared plugin/app choices, public MCP endpoints, the default `high` reasoning
effort, and `air`/`pro`/`studio` overrides. It never contains credentials.
`mac-sync` applies this profile; `sync-maintain` captures local on/off changes
into that Mac's override instead of changing every Mac's defaults.

PDF, documents, spreadsheets, presentations, visualization and plugin management
remain enabled. ChatGPT email/Calendar, unused app plugins and rare cloud MCPs
are disabled in Codex without disconnecting their ChatGPT.com accounts.
Account-managed plugins can still appear enabled in the inventory: the
profile also applies Codex per-app `enabled` controls, derived from reviewed
public `.app.json` connector IDs. Local plugin toggles update these controls
without changing account installation or authorization. App tools default
to off, with plugin management enabled. See the [Codex app configuration
reference](https://learn.chatgpt.com/docs/config-file/config-reference).
Context7 is enabled by default on all three Macs. Credentials remain machine-local.
Pro alone has a tracked QGIS server definition. App-specific servers are never
installed on other Macs by a toggle; missing executables are disabled. The
retired Exa and ChatGPT-desktop browser/computer-use MCP definitions are removed.
T3's native browser tools are independent of those retired definitions.

Change a managed tool on just the current Mac, then review/publish the profile
with the usual dotfiles workflow:

```sh
python3 ~/.config/sync/codex-technical.py set-mcp context7 on
python3 ~/.config/sync/codex-technical.py set-plugin gmail@openai-curated-remote off
python3 ~/.config/sync/codex-technical.py apply
```

Edit the shared entries in the JSON deliberately when changing defaults for
all Macs. Local MCP headers, OAuth state, other settings and unreviewed local
server definitions remain local. API keys and account connections are never
copied between Macs or committed. Disabled tools retain their local credentials.
A local stdio server remains authoritative over a same-named shared remote
endpoint. New local command definitions require explicit review before tracking.

Artifact skills such as PDF are installed and updated by their Codex plugins,
not copied through Git; Codex can load them when a matching task needs them.

Run `python3 ~/.config/sync/codex-technical.py restore-plugins` only when
missing enabled plugins need installation; disabled plugins are skipped.
Caches, conversations, full Codex configuration, account state and trusted
project paths remain untracked. Models and existing T3 thread selections stay
local; the shared reasoning effort is a default, not an override of an
explicit thread choice. The new profile tests cover isolated toggles,
credential preservation, retired definitions, missing app executables and
idempotent application; all 41 sync tests passed on Air on 2026-11-02.
QGIS MCP 0.15.2 initialized, listed 125 tools and read a blank EPSG:4326
project with zero layers while QGIS was open on Pro. Calls with its GUI
bridge closed failed with connection refused; that is an app prerequisite,
not missing Codex authentication. No project edits were made.
Final checks also passed 41 sync tests on Pro and 37 on Studio; their older
repository baselines contain different test populations. Studio's Codex CLI
was upgraded from 0.147.0 to the same 0.166.0 used on Air and Pro. The old
CLI lacked `--print-startup-config`; effective settings were verified through
`config/read` under strict configuration validation before the upgrade.
The shared profile was verified across all three Macs; the custom handoff skill is retired.

### New Mac

1. Follow the root dotfiles bootstrap instructions until the bare repository
   exists.
2. Run `~/.config/sync/install-agent.sh`.
3. Run `mac sync` to reconcile the Herdr login agent. It preserves an already
   running server instead of repeatedly attempting a duplicate start.
4. Make Homebrew Fish the account login shell:

   ```fish
   grep -qxF /opt/homebrew/bin/fish /etc/shells; or \
       echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/fish
   ```

5. Open Ghostty and verify that it starts Fish, attaches to Herdr, and opens a
   Fish pane. `echo $HERDR_ENV` should print `1` inside that pane.
6. Handle manual sign-ins, licenses, App Store authentication, and macOS
   privacy permissions.

Herdr logs, sockets, cached manifests, session state, and pane history are
machine-local. Only `~/.config/herdr/config.toml` and its helper scripts belong
in dotfiles. The superseded tmux, skhd, yabai, and Micro configurations have
been removed.

## Agent Contract

Agents working on this setup must follow these rules:

1. Read this entire file before changing dotfiles, Mac synchronization,
   Ghostty, Herdr, VS Code, fish, or keymaps.
2. Use the bare dotfiles repository; do not recreate tracked configuration.
3. Use VS Code for editing and Ghostty and Herdr for terminal work.
4. Keep this as the only Markdown file under `~/.config`. Update it instead of
   adding repository-specific agent or README files.
5. Do not sync secrets, tokens, browser profiles, histories, caches, keychains,
   databases, or machine-local state.
6. Prefer Homebrew for packages and casks.
7. Treat applications as shared unless Fausto uses a local or skip command;
   keep formulae local unless deliberately added to `packages.txt`.
8. Only entries explicitly recorded in `retired-apps.tsv` may cause app
   removal during sync.
9. Publish completed agent-made Mac changes automatically after relevant checks:
   stage the task's portable configuration, manifests, scripts and documentation,
   commit, and push the bare dotfiles repository without asking again. Preserve
   unrelated or unfinished edits and exclude secrets and machine-local state.
   `mac-app` publishes its manifest targets; App Shortcuts sync publishes only
   its separate `app-shortcuts` data branch.
10. Global app retirement also removes its unused tracked configuration,
    app-specific helpers/tests, keybindings and sync/capture hooks. Publish these
    deletions with the retirement entry, which prevents later reinstall. Missing
    software on one Mac or an offline Mac does not establish global retirement.

For every custom keybinding change:

1. Update `~/.config/keymaps/registry.tsv`, preserving unique IDs.
2. Update the relevant VS Code, Karabiner, Ghostty, or Herdr
   configuration and include its `km:<id>` marker.
3. Keep modifier roles consistent with the Keyboard Layers section.
4. Run `~/.config/keymaps/keymap-docs` to regenerate the table in this file.
5. Run `~/.config/keymaps/keymap-docs --check` and relevant configuration tests.

Do not add an undocumented binding, reuse a key in one layer, or assign a
modifier a new role without explicit approval.

For periodic sync maintenance:

1. Run `sync-maintain`.
2. Inspect `bare status` and relevant diffs.
3. Report installations and any one-time permissions still needed.
4. Commit and push the completed changes automatically after checks. For a
   scoped agent task, use explicit paths and a descriptive message so unrelated
   concurrent edits stay intact; `bcp` remains available for interactive use.
5. Reconcile reachable Macs with the published version and report any network,
   permission or push failure. Never silently leave completed changes unpublished.

For a new Mac, verify `bare pull --ff-only` and `bare status`, run the installer
and maintenance script, then report missing manual sign-ins and permissions.

## Maintenance Checks

For workflow skill edits, run
`uv run --no-project --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/fausto-workflow`.
Validation (2026-11-10): skill validation, five bcp tests, keymap consistency,
shell syntax and whitespace checks passed. Maintenance stages only this custom
skill; managed skills and plugin caches remain untracked.

Use these after changing the setup:

```fish
keymap-docs --check
bash -n ~/.local/bin/mac-app ~/.local/bin/mac-sync ~/.config/sync/*.sh ~/.config/mac-setup/*.sh
python3 ~/.config/sync/test-mac-sync.py
python3 ~/.config/sync/test-bcp.py
python3 ~/.config/sync/test-vscode-local.py
python3 ~/.config/sync/test-background-cleanup.py
python3 ~/.config/sync/test-helium-apps.py
/usr/bin/python3 ~/.config/sync/test-helium-extensions.py
/usr/bin/python3 ~/.config/sync/test-mac-commands.py
/usr/bin/python3 ~/.config/sync/test-manual-actions.py
python3 ~/.config/sync/helium-apps.py check
jq empty ~/.config/karabiner/karabiner.json
plutil -lint ~/.config/mac-setup/com.fausto.mac-sync.plist
mac-sync --no-pull
herdr config check
fish --no-execute ~/.config/fish/config.fish
```

Some health output is informational. Report exact failures instead of hiding
them. Keep the setup small: add a plugin or tool only when it removes recurring
friction that existing tools cannot solve clearly.

The custom `research-handoff` skill is retired on all Macs. After `bare pull`,
run `python3 ~/.config/sync/codex-technical.py apply` to remove the local copy.
The OpenAI-provided PDF plugin remains enabled.

## Security baseline (2026-11-05)

The login/hourly job runs `mac-sync --scheduled --quiet`: the existing reviewed
shortcut helper exchanges JSON data on its separate Git branch, then a local
manifest check reports missing applications/packages. It does not fetch or
execute incoming dotfiles, install apps/extensions, rewrite app preferences,
or delete retired data. Diagnostic state in `~/.local/state/mac-sync/check.json`
suppresses repeated unchanged reports. `mac-sync --check` checks without even
exchanging shortcut data. Manual checks return 1 for manifest drift; scheduled
checks report drift without failing the job. Exit 2 means an execution error.
A plain `mac-sync` applies the current checkout without pulling; `--pull` is
explicit and still refuses incoming changes while tracked/staged work is dirty.
The separate approved `mac-update` app updater retains its existing policy.

`python3 ~/.config/mac-setup/security-baseline.py user` restricts T3 userdata
to 0700 and known credential files to 0600. Its explicit `system` mode requires
sudo, validates/removes the obsolete Vorssaint sudo rule, protects Studio's
existing daemon directory without restarting Tailscale, enables the firewall
with SSH/Tailscale/T3 exceptions, and removes the dormant Public Folder SMB
share and guest access. It installs no daemon or passwordless sudo permission.
The archived sudo rule is root-only in `/var/db/com.fausto.mac-security/`.
FileVault enrollment/recovery is machine-local; no keys or credentials belong
in this repository. Fausto explicitly declined Time Machine and additional cross-Mac copies.
GitHub/iCloud remain the selected recovery routes; loss of local-only work
is accepted. Only committed and pushed content is recoverable from GitHub.

Verify with `python3 ~/.config/sync/test-sync-check.py`, the existing sync
tests, `mac-sync --check`, `fdesetup status`, and the firewall/ownership checks.

Safari extension apps uBlock Origin Lite, Picture-In-Picture, and Accelerate are retired across Macs via `retired-apps.tsv` and `mac-sync`.
