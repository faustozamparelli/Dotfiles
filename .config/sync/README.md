# Fausto's Terminal Workspace Manual

This is the single human and agent manual for this dotfiles setup. It explains
the working model, the custom keymaps, the terminal tools already installed,
and the rules for safely changing or synchronizing the configuration.

The primary workspace is Ghostty with Herdr and Neovim:

```text
Ghostty
└── Herdr
    ├── Neovim
    ├── fish
    └── Codex agent tabs
```

Open a project in Neovim with `nvim .` (or `n .` in fish).

## App Sync

Use `mac-app` for applications so they are installed on this Mac now and on
the other Mac automatically at login or within an hour:

```sh
mac-app firefox
mac-app share --mas 497799835 Xcode
mac-app local transmission
mac-app temporary handbrake
mac-app skip spotify
mac-app remove spotify
```

Homebrew casks are the default source. App Store apps use their numeric ID,
and exceptional direct downloads use a reviewed checksum-pinned installer.
Shared command-line utilities are deliberately curated in
`~/.config/mac-setup/packages.txt`; arbitrary formulae remain temporary and
local. `mac-sync --nuke` removes temporary formulae while retaining dependencies
still needed by the curated set. The sync removes apps only when they are
explicitly recorded for retirement.

## Neovim Workspace

Open Ghostty and let fish attach to the persistent Herdr session. Start
Neovim from a project root with `nvim .`. The tracked configuration lives
in `~/.config/nvim`, and `packages.txt` installs Neovim on each Mac.
The keymap reference below describes the editor bindings.

## Ghostty and Herdr Terminal Workspace

Ghostty, Herdr, and Neovim form the main terminal workspace.

Open Ghostty. Its fish configuration automatically attaches to the persistent
Herdr session. Work survives accidental terminal-window closes.

Finder opens text and source files with the configured macOS default apps.
The tracked choices are in `~/.config/duti/defaults.duti`.

The essential loop is:

1. Use `z <project-name>` to jump to a known project.
2. Run `nvim .` to open that directory in Neovim.
3. Use `Space e` or `-` to browse with Oil.
4. Use `Space f f` to find a file and `Space f b` to switch buffers.
5. Use `Space f a` to jump to a file or project outside the current project.
6. Press `Cmd-g` when an agent is useful.
7. Use `Cmd-b` or `Cmd-n` only when another shell pane is genuinely needed.
8. Press `Ctrl-Space ?` for searchable custom-keymap help.

An example:

```fish
z my-project
nvim .
```

Inside Neovim, `:pwd` shows the directory used by file search, text search,
Git commands, and newly opened terminal processes.

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
│   ├── pane: Neovim
│   └── pane: Codex
└── workspace: project-b
    └── tab 1: editor
    ├── pane: Neovim
    └── pane: shell
```

Use one Herdr workspace per project and tabs for independent layouts within
that project. A pane is a temporary view, not a substitute for a project. New
panes, tabs, and workspaces inherit the current pane's directory.

### Neovim owns editing

Neovim has several different containers:

- A buffer is an open file or terminal. A buffer can exist without being shown.
- A window is a viewport displaying one buffer.
- A tab page is a collection of Neovim windows, not a file tab.
- The argument list is the set of files supplied when Neovim started.

Do not create a split for every file. Open files into the current window and
switch among buffers with `Space f b`. Use a split only when two things must be
visible simultaneously.

### The working directory defines project scope

The current working directory controls relative paths and the default scope of
fzf-lua, Git, and terminal commands. Start Neovim from the project root:

```fish
z project-name
nvim .
```

Useful checks and corrections inside Neovim:

```vim
:pwd
:cd /absolute/project/path
:cd %:p:h
```

The last command changes to the directory containing the current file. Avoid
Neovim's `autochdir`: silently changing scope when switching buffers makes
project search and agent behavior unpredictable.

## Keyboard Layers

The configuration assigns each modifier a stable job:

- `Right Cmd` (`Super`): global macOS windows, workspaces, and app launchers.
- `Ctrl-h/l`: move between Herdr workspaces.
- `Cmd`: frequent Herdr tab and pane operations.
- `Alt`: directional Herdr pane focus; adding Shift resizes.
- `Space`: discoverable Neovim operations.
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
| Neovim | Space | `Space Space` | Save the current file |
| Neovim | Space | `Space e` | Open Oil file browser |
| Neovim | Direct | `-` | Open the parent directory in Oil |
| Neovim | Space | `Space f f` | Find files |
| Neovim | Space | `Space f a` | Find files or projects across working roots |
| Neovim | Space | `Space f b` | Find open buffers |
| Neovim | Space | `Space f r` | Find recent files |
| Neovim | Space | `Space f h` | Search Neovim help |
| Neovim | Space | `Space g s` | Open Git status picker |
| Neovim | Space | `Space g b` | Show line blame |
| Neovim | Space | `Space g d` | Diff the current file |
| Neovim | Space | `Space g n` | Go to next Git hunk |
| Neovim | Space | `Space g p` | Go to previous Git hunk |
| Neovim | Space | `Space l r` | Rename symbol |
| Neovim | Space | `Space l a` | Open code actions |
| Neovim | Space | `Space l d` | Search workspace diagnostics |
| Neovim | Space | `Space l f` | Format the current buffer |
| Neovim | Space | `Space b l` | Select next buffer |
| Neovim | Space | `Space b h` | Select previous buffer |
| Neovim | Space | `Space b d` | Delete current buffer |
| Neovim | Space | `Space q q` | Close the current window |
| Neovim | Space | `Space q a` | Quit Neovim |
| Neovim | Space | `Space ?` | Open keymap help |
| Neovim | Direct | `H` | Move to first nonblank character |
| Neovim | Direct | `L` | Move to end of line |
| Neovim | Direct | `U` | Redo the last change |
| Neovim | Direct | `J` | Move selected lines down |
| Neovim | Direct | `K` | Move selected lines up |
| VS Code | Command | `Cmd-h` | Select the previous editor tab |
| VS Code | Command | `Cmd-l` | Select the next editor tab |
| VS Code | Command | `Cmd-Shift-h` | Move the current editor tab left |
| VS Code | Command | `Cmd-Shift-l` | Move the current editor tab right |
| VS Code | Command | `Cmd-b` | Split the editor to the right |
| VS Code | Command | `Cmd-n` | Split the editor below |
| VS Code | Command | `Cmd-w` | Close the active editor tab |
| VS Code | Command | `Cmd-t` | Show the terminal in an editor tab or return to the previous file |
| VS Code | Command | `Cmd-Shift-t` | Open a terminal beside the editor |
| VS Code | Command | `Cmd-e` | Show or hide the file explorer |
| VS Code | Command | `Cmd-g` | Show or hide Source Control |
| VS Code | Command | `Cmd-a` | Return to Vim Normal mode |
| VS Code | Alt | `Alt-h` | Focus the pane to the left |
| VS Code | Alt | `Alt-j` | Focus the pane below |
| VS Code | Alt | `Alt-k` | Focus the pane above |
| VS Code | Alt | `Alt-l` | Focus the pane to the right |
| VS Code | Space | `Space Space` | Save the current file |
| VS Code | Space | `Space f f` | Find files in the current project |
| VS Code | Space | `Space f g` | Search text across project files |
| VS Code | Space | `Space f b` | Find open editors |
| VS Code | Space | `Space f r` | Open a recent file or project |
| VS Code | Space | `Space g d` | Diff the current file |
| VS Code | Space | `Space g n` | Jump to the next changed block |
| VS Code | Space | `Space g p` | Jump to the previous changed block |
| VS Code | Space | `Space l r` | Rename the symbol |
| VS Code | Space | `Space l a` | Show available code actions |
| VS Code | Space | `Space l f` | Format the current file |
| VS Code | Space | `Space l d` | Show workspace problems |
| VS Code | Space | `Space b l` | Select the next editor tab |
| VS Code | Space | `Space b h` | Select the previous editor tab |
| VS Code | Space | `Space b d` | Close the active editor tab |
| VS Code | Space | `Space ?` | Open VS Code keyboard shortcuts |
| VS Code | Direct | `H` | Move to the first nonblank character |
| VS Code | Direct | `L` | Move to the end of the line |
| VS Code | Direct | `U` | Redo the last change |
| VS Code | Direct | `J` | Move selected lines down |
| VS Code | Direct | `K` | Move selected lines up |
| VS Code | Space | `Space e` | Open the project file explorer |
| VS Code | Space | `Space a c` | Open the Codex sidebar |
| VS Code | Space | `Space m p` | Open rendered Markdown |
| VS Code | Space | `Space f F` | Reveal the current file in Finder |
| VS Code | Space | `Space l s` | Search workspace symbols in available indexes |
| VS Code | Space | `Space l p` | Open the symbol definition or Python source |
| VS Code | Space | `Space b k` | Close the active editor like Neovim |
| VS Code | Direct | `cm (Normal)` | Toggle comment on the current line |
| VS Code | Direct | `cm (Visual)` | Toggle comment on selected lines |
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

Before opening it, make sure the Neovim/shell pane belongs to the correct
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

## Neovim in Practice

### Modes and escape

- Normal mode performs commands and movement.
- Insert mode enters text; press `i`, `a`, `o`, or `O` to enter it.
- Visual mode selects text; press `v`, `V`, or `Ctrl-v`.
- Command-line mode begins with `:`.
- Terminal mode sends keys to a process.

Press `Esc` to return toward Normal mode. `Cmd-a` sends Escape through
Ghostty, and in Neovim it also clears active `/` search highlighting.

### Movement worth learning

```text
h j k l       left, down, up, right
w / b         next / previous word
e             end of word
0             physical start of line
H / L         first nonblank / end of line (custom)
gg / G        first / last line
{ / }         previous / next paragraph
%             matching bracket
Ctrl-d/u      half-page down / up
zz            center current line
f<char>       next character on line
t<char>       just before next character
; / ,         repeat character motion forward / backward
```

Prefix a motion with a count: `5j`, `3w`, or `2}`. Relative line numbers make
counted vertical movement easy.

### Operators compose with motions

Vim editing is a small language:

```text
d + motion    delete
c + motion    change, then enter Insert mode
y + motion    yank (copy)
> / <         indent / unindent
```

Examples:

```text
dw            delete to the next word
ciw           change inside word
ci"           change inside quotes
di(           delete inside parentheses
yap           yank a paragraph
dd / yy       delete / yank a line
p / P         paste after / before
.             repeat the last change
u / U         undo / redo (U is custom)
```

Learn text objects such as `iw`, `aw`, `i"`, `a(`, `it`, and `ap`; they remove
much of the need for precise visual selection.

### Search and replace

```text
/pattern      search forward
?pattern      search backward
n / N         next / previous match
* / #         search current word forward / backward
:noh          remove search highlighting
```

Common replacements:

```vim
:s/old/new/g
:%s/old/new/gc
:'<,'>s/old/new/g
```

The second replaces throughout the file and asks for confirmation. The third
operates on the current visual selection.

### Files with Oil

`Space e` opens Oil for the current directory. `-` opens the parent directory.
Oil behaves like an editable directory buffer:

- `Enter` opens the selected file or directory.
- `Ctrl-s` opens in a vertical split.
- `Ctrl-h` opens in a horizontal split.
- `Ctrl-t` opens in a Neovim tab page.
- `-` moves to the parent directory.
- `_` opens Neovim's current working directory.
- `g.` toggles hidden files.
- `gs` changes sorting.
- `g?` displays Oil help.

Rename, move, create, or delete filesystem entries by editing their lines as
text, then write with `Space Space`. Oil previews the operations before applying
them. Deleted items go to Trash in this configuration.

### Finding instead of browsing

Prefer fuzzy finding when the destination is roughly known:

- `Space f f`: files under the working directory.
- `Space f a`: files and directories across the main working roots.
- `Space f b`: currently open buffers.
- `Space f r`: recently opened files.
- `Space f h`: Neovim help topics.

Inside an fzf-lua file picker, `Enter` opens normally, `Ctrl-s` opens a
horizontal split, `Ctrl-v` opens a vertical split, and `Ctrl-t` opens a tab.
Typing narrows results; `Esc` cancels.

### Searching across working roots

`Space f a` is the fast path when the destination is outside the current
project. It searches these locations in one picker:

- `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/ShortTerm`
- `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/LongTerm`
- `~/Developer`
- `~/.config`
- immediate children of `~`

The first four roots are recursive. Home is deliberately limited to its first
level so the picker does not walk all of `~/Library` or duplicate the other
roots. Generated and dependency directories such as `.git`, `node_modules`,
`.venv`, `build`, `dist`, and `target` are excluded.

The selected path determines the action:

- A directory becomes Neovim's working directory, is added to zoxide, and
  opens in Oil. From then on, project search, Git, terminals, and agent panes
  use that directory as project scope.
- A text or structured-data file opens as a normal Neovim buffer without
  changing the current project.
- A PDF, image, office document, archive, or other non-text file opens with
  the default macOS application.

Use `Space f f` after switching to a directory when only that project should be
searched. Use `Space f a` again when crossing project boundaries.

### Buffers, windows, and tabs

- `Space f b` is the normal buffer switcher.
- `Space b h/l` moves to the previous/next buffer.
- `Space b d` deletes the current buffer.
- `Ctrl-w h/j/k/l` moves among Neovim windows.
- `Ctrl-w v` and `Ctrl-w s` create vertical/horizontal splits.
- `Ctrl-w =` equalizes split sizes.
- `:tabnew`, `gt`, and `gT` create and move among tab pages.

Use Herdr panes for independent processes and Neovim windows for simultaneous
views of editor buffers. Avoid nesting layouts without a reason.

### Git inside Neovim

- `Space g s` opens the repository status picker.
- `Space g b` shows blame for the current line.
- `Space g d` diffs the current file.
- `Space g n/p` moves to the next/previous changed hunk.

Gitsigns marks added, changed, and removed lines in the sign column. Use the
shell for commits until a dedicated Neovim commit workflow is intentionally
added.

### Language intelligence

Python uses Pyright and Ruff; C and C++ use macOS `clangd`. These files format
before save.

- `Space l r`: rename a symbol across the project.
- `Space l a`: available code actions.
- `Space l d`: workspace diagnostics.
- `Space l f`: format now.
- `K`: language documentation in Normal mode, except in Visual mode where the
  custom mapping moves selected lines upward.
- `gd`: go to definition when provided by the active LSP.

Use `:LspInfo` and `:checkhealth vim.lsp` when language features are absent.

### Built-in help and diagnosis

Neovim's help is searchable with `Space f h`. Useful topics:

```vim
:help motion.txt
:help operator
:help text-objects
:help windows
:help buffers
:help :terminal
:help lua-guide
:checkhealth
:messages
```

In help, place the cursor on a `|tag|` and press `Ctrl-]`; press `Ctrl-o` to go
back.

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

Quote paths containing spaces: `n "My Notes/file.md"`. Press `Tab` for
completion, `Up` for history, `Ctrl-r` for searchable history, `Ctrl-c` to
interrupt a running command, and `Ctrl-d` to end an idle shell.

### Navigation and inspection

```fish
pwd                       # print current directory
z project-name            # jump using zoxide's learned history
cd ..                     # parent directory
l                         # eza listing, including hidden files and Git state
b file.py                  # syntax-highlighted file output with bat
rg 'text'                  # recursively search file contents
rg --files                 # list searchable files
fzf                        # fuzzy-select input paths
open .                     # open current directory in Finder
```

`zoxide` learns directories after you visit them. Use `z foo` rather than
typing a long path. Use `zi` for interactive fuzzy directory selection.

### Filesystem changes

Prefer Oil for interactive changes. When the shell is clearer:

```fish
mkdir -p path/to/folder
touch new-file.txt
cp source destination
mv old-name new-name
rm file
```

`rm` bypasses Trash and is irreversible by default. Inspect paths first. Use
Oil for deletions when possible because this setup sends them to Trash.

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
n          Neovim
l / ls     eza -a --git
b          bat
o          open
cl         clear
py         Homebrew Python (alias for python)
python     stable Homebrew Python command maintained by mac-sync
sv         activate .venv for fish
nb         jupyter lab
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
b ~/.config/fish/config.fish
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

`nb` opens JupyterLab. Create a `uv` project and add the libraries it needs
before using notebooks or Python scripts for that project. C and C++ course
work uses the professor's container rather than shared Mac packages.

Use a project's declared dependencies instead of installing packages globally.

### AMSC container with Mac Neovim

The `amsc` Fish alias starts the professor's container and opens Bash in
`/shared-folder`. That directory is `~/shared-folder` on the Mac, so edit there
with Neovim outside Docker and run builds inside Docker:

```fish
amsc
module load gcc-glibc/11.2.0
module load lis/2.0.30
gcc myprogram.c -I"$mkLisInc" -L"$mkLisLib" -llis -o myprogram
```

For files under `~/shared-folder`, Neovim starts `clangd` inside the running
container. The wrapper maps Mac file paths to `/shared-folder` and loads the
GCC toolchain. While the container is running, `mac-sync --no-pull` discovers
its installed library headers and writes `~/shared-folder/.clangd`. This gives
Neovim completion, diagnostics, and formatting for the container's C/C++
libraries without installing them on macOS. Start `amsc` before opening a
shared-folder project in Neovim; run `mac-sync --no-pull` again if the
container's library set changes. Container-only header files cannot be opened
directly on the Mac. Other C/C++ files use macOS's built-in `clangd`.

The current container has Ubuntu `clangd` installed. A newly created AMSC
container needs it once; after starting that container, run on the Mac:

```sh
docker exec -u root amsc apt-get update
docker exec -u root amsc env DEBIAN_FRONTEND=noninteractive apt-get install -y clangd
mac-sync --no-pull
```

For a project needing module-specific macros or compiler options, generate its
[`compile_commands.json`](https://clangd.llvm.org/installation.html#compile_commandsjson)
inside the container so its commands and paths name the Linux compiler and
headers. `clangd` reads that database through the shared folder. Build and run
course code only inside the container after loading the modules it needs.

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

Edit the `.py` file in Neovim or VS Code and use Ruff, Pyright, ripgrep, Git diff, or
coding agents on it. Run `jupytext --sync notebook.py` after script edits.
JupyterLab's Jupytext extension maintains explicitly paired files when saving
in the UI. No project-wide pairing rule is set; existing notebooks stay as
they are. `mac-sync` restores the extension after a JupyterLab upgrade.

### Jujutsu with Git

`jj` is available for local changes; Git and `gh` remain installed. In a clean,
chosen Git repository, `jj git init --git-repo=.` adds a colocated `.jj`
without converting any other repository. Try the practice repo in
`/private/tmp/jj-practice-*` first:

```fish
jj status                 # working copy status
jj diff                   # current change, shown with delta
jj log                    # change graph
jj describe -m "message"  # name the current change
jj new                    # start a fresh change
jj undo                   # undo the last jj operation
jj redo                   # redo a just-undone operation
```

A colocated repo may show a detached Git HEAD. Check `jj status` and
`git status` before mixing mutations from both tools. Git branches, remotes,
GitHub, and `gh` remain available. LazyGit has been uninstalled; Neovim's Git
picker remains.

### VS Code

VS Code is shared through `apps.tsv` alongside the terminal workspace.
Its last tracked configuration before retirement was restored from the parent
of commit `bc45353`, including Vim navigation and the existing themes.
The bare dotfiles repository tracks only
`~/Library/Application Support/Code/User/settings.json`, `keybindings.json`,
`tasks.json`,
`~/.config/sync/vscode-extensions.txt`, and `vscode-disabled-extensions.txt`.
`sync-maintain` stages these files;
`mac-sync` installs missing listed extensions on each Mac. Extension binaries,
credentials, workspace storage, logs, and caches stay local.

The extension list retains Vim, Python, Pylance, clangd, Ruff, Codex, and the
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
source. Git diffs keep the source text. This uses no extra preview extension.

The Fish login terminal uses the existing prompt, aliases and toolchain PATH;
Herdr only starts automatically in Ghostty, so it does not nest inside VS Code.
Terminal splits inherit the current directory and persistent sessions are
explicitly enabled. Vim uses smart-case searching and Neovim's 400 ms mapping
timeout. Added equivalents include `Space e` (Explorer), `Space a c` (Codex),
`Space m p` (Markdown preview), `Space f F` (Finder), `Space l s` (symbols),
`Space l p` (definition/Python source), `Space b k` (close), and `cm` (comments).
Python defaults to the project `.venv` for newly opened workspaces; an already
selected interpreter must be changed with **Python: Select Interpreter**.

VS Code's clangd now uses the same `amsc-clangd.sh` bridge as Neovim. Open
`~/shared-folder` or one of its project subdirectories in its own VS Code
window. For these folders the bridge runs Linux clangd in the running AMSC
container, maps file paths, loads GCC 11.2 and queries its system headers.
Outside this tree it uses native macOS clangd. If the container is stopped,
the bridge reports how to start it rather than producing misleading Mac
compiler diagnostics for Linux code. VS Code's two-worker/no-background-index
arguments are forwarded; Neovim's existing defaults remain unchanged.

For direct access to Linux headers, use **Dev Containers: Attach to Running
Container... → amsc**. The tracked `~/.config/mac-setup/vscode-amsc.json` is
merged into the local named-container configuration by `vscode-amsc.py` during
sync. It opens `/shared-folder` as `ubuntu`, installs Linux clangd/C++/Vim
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

PDF clicks open the macOS default app (currently Preview) through the tiny
tracked local `fausto.preview-pdf` opener. It activates only for PDF files,
opens the local file externally and closes its own temporary editor tab.
For the attached AMSC window it maps `/shared-folder` to `~/shared-folder`.
Other remote PDFs must be downloaded first. `install-vscode-local.py` packages
and installs this extension during sync; it has no npm dependencies and its
source is tracked under `~/.config/sync/vscode-preview-pdf`. Generated VSIX files
and installed extension directories stay local. Reload the VS Code window
after an update to this local extension if VS Code requests it.

Useful built-in tools for reviewing generated code are notebook diffs, Variable
Explorer/Data Viewer, the Problems panel, tests, debugger watches, selective Git
staging and separate Git worktrees for concurrent agent changes. Extra Lua/TOML
extensions are not priorities for the current Python/C++ workload. Oil's editable
directory buffers and Herdr's agent/worktree management still have no exact
built-in equivalents. Fish keeps `EDITOR`/`VISUAL` as Neovim during the trial.

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

Two optional extensions add distinct functionality, but neither is installed
by the shared manifest:

- [Jupytext Sync](https://marketplace.visualstudio.com/items?itemName=caenrigen.jupytext-sync)
  (`caenrigen.jupytext-sync`) keeps explicitly paired notebooks and `.py`
  files synchronized on save. This is useful when Codex edits the text version
  while the notebook UI shows outputs. It needs Jupytext in the Python
  environment it selects. The existing CLI workflow remains sufficient for
  manual sync; the Jupyter extension already runs `# %%` Python cells.
- [JJ View](https://marketplace.visualstudio.com/items?itemName=jj-view.jj-view)
  (`jj-view.jj-view`) adds a Jujutsu graph and change management in the editor.
  Consider it only for repositories actively using `jj`. Its defaults include
  polling and recursive repository detection. If adopted, use
  `jj-view.fileWatcherMode: "watch"` and
  `jj-view.autoRepositoryDetection: false` to prefer native events and workspace
  roots; the watcher may still fall back to polling.

Documentation verified through Context7 `/microsoft/vscode-docs` and
`/websites/astral_sh_uv`, plus [uv notebooks](https://docs.astral.sh/uv/guides/integration/jupyter/)
and [OrbStack debugging](https://docs.orbstack.dev/machines/#debugging-with-gdb-lldb).

To diagnose a recurring spike, run `code --status` while it happens and use
**Developer: Open Process Explorer** to identify the busy process. If the
extension host is responsible, run **Help: Start Extension Bisect**. Test with
the actual project before concluding that a previous CPU issue is resolved.

### Codex

The preferred entry point is `Cmd-g`, which creates or focuses the project
agent pane. From a shell, `codex` starts it directly. Agents inherit their
starting directory, so project selection comes before agent startup.

Provide concrete requests: desired outcome, relevant files, constraints, and
verification. Ask the agent to inspect before editing when the problem is not
yet understood.

## Common Workflows

### Begin work on a project

```fish
z project-name
git status
nvim .
```

Then use `Space f f` and `Space f b`. Press `Cmd-g` if the task
benefits from an agent.

### Work on two projects

1. Open the first project and Neovim.
2. Press `Ctrl-Space Shift-n` to create another Herdr workspace inheriting the current
   path.
3. Use `z other-project`, then `nvim .`.
4. Switch projects with `Ctrl-h` and `Ctrl-l`.

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

```fish
nvim ~/.config
```

Use `Space f f` to locate the relevant configuration. After keymap changes run:

```fish
keymap-docs
keymap-docs --check
```

After Herdr changes press `Ctrl-Space Shift-r`. Restart Neovim after plugin or startup
changes. Ghostty reload behavior depends on the setting changed; reopening it
is the reliable option.

## Mac Synchronization

The MacBook Air and MacBook Pro use one shared app manifest. Apps are shared by
default; formulae are shared only when intentionally listed in
`~/.config/mac-setup/packages.txt`. Run an immediate reconciliation with:

```fish
mac-sync
```

Install an experimental formula normally with `brew install`; it remains local
and temporary. Add only frequently used or current-project formulae to
`packages.txt`. To remove every temporary top-level formula and any dependency
that is no longer needed, run:

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
mac-app skip spotify
mac-app unskip spotify
mac-app remove spotify
mac-app remove --mas 497799835
```

`mac-app` records, commits, and pushes app changes. A LaunchAgent pulls and
reconciles at login and hourly. Per-Mac app lists and skip lists live under
`~/.config/mac-setup/machines/`. Direct downloads require a checksum-pinned
installer under `direct/`. `mac-app remove` takes a shared app identifier,
removes its row from `apps.tsv`, records the exact row in `retired-apps.tsv`,
and runs `mac-sync` locally. Run `mac-sync` manually on the other Mac to apply
the removal there; its scheduled sync may apply it sooner. Ordinary manifest
edits do not uninstall software. Sharing or locally installing a retired app
again clears its retirement entry.

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
Mac; VS Code is shared again and Neovim is installed from `packages.txt`.

`sync-maintain` runs the same convergence check, regenerates keymap docs, and
stages maintained dotfile paths. `bcp` then asks for a commit message and
pushes.

### Portable app performance settings

`~/.config/sync/app-preferences.json` shares a reviewed whitelist of performance
preferences for installed apps. `app-preferences.py apply` runs during
`mac-sync`; `capture` runs before reconciliation during `sync-maintain` so
changes made in the apps can be staged. Full application plists stay local.
The portable Qalculate numeric/formatting preferences in
`~/.config/qalculate/qalc.cfg` are tracked; calculation histories stay local.

Vorssaint keeps temperature readings with a supported five-second refresh;
unused network monitoring is disabled. CodexBar uses adaptive refresh and
follows system Low Power Mode. Its provider IDs, enabled choices and selected
source are shared through the whitelist, merged into
`~/.config/codexbar/config.json` while preserving local credentials. The old
tracked `~/.codexbar/config.json` was an inactive duplicate and has been removed.

Ghostty uses a non-blinking default cursor and keeps vsync enabled. Neovim
checks macOS appearance every thirty seconds and when regaining focus instead
of launching `defaults` every two seconds.

`python3 ~/.config/mac-setup/cleanup-orphan-app-data.py --delete` removes only a reviewed,
explicitly approved list of obsolete app-data folders after checking app bundles,
executables and running processes. Existing installations keep their data.
Discord, GitButler and Tor Browser also require their retirement entries.
This never removes project or document directories. macOS Full Disk Access may
be needed for protected folders. Without `--delete`, the script archives data
locally for review instead of permanently deleting it.

### Codex technical setup

Custom skills under `~/.codex/skills/context7-docs`, `grill-me`, and
`spam-senders`, plus `~/.agents/skills/context7-mcp`, are tracked in dotfiles.
`~/.config/sync/codex-technical.json` records installed plugin IDs and
explicit enabled/disabled choices from Codex config, including remote
integrations the CLI plugin list may omit, plus the public HTTPS addresses of
remote MCP servers. `sync-maintain` captures
these choices and stages them for review; after commit and push, `mac-sync`
merges them into `~/.codex/config.toml` on the other Mac at login or hourly.
Existing local MCP headers, credentials, and machine-specific servers remain
untouched. Plugin files and caches are installed by Codex, not copied through
Git. To install missing plugins on the other Mac, run
`python3 ~/.config/sync/codex-technical.py restore-plugins` there after sync;
it uses the Codex plugin installer and may need account authorization. API
keys and account connections must be set up locally.

Model, theme, fonts, desktop appearance, Dock and update preferences are local
choices and are not captured. Neither the full Codex config nor conversations,
trusted project paths, plugin caches, MCP secrets, or app state are tracked.
The technical snapshot is a selected list: a new custom skill or local MCP
server needs deliberate review before it is added to dotfiles.

### New Mac

1. Follow the root dotfiles bootstrap instructions until the bare repository
   exists.
2. Run `~/.config/sync/install-agent.sh`.
3. Run `brew services start herdr`. This installs a per-user launch agent with
   `RunAtLoad` and `KeepAlive`, so the Herdr server returns after login/reboot.
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
   Ghostty, Herdr, Neovim, fish, or keymaps.
2. Use the bare dotfiles repository; do not recreate tracked configuration.
3. Use Ghostty, Herdr, and Neovim for the primary workspace. Keep the
   tracked Neovim configuration current.
4. Keep this as the only Markdown file under `~/.config`. Update it instead of
   adding repository-specific agent or README files.
5. Do not sync secrets, tokens, browser profiles, histories, caches, keychains,
   databases, or machine-local state.
6. Prefer Homebrew for packages and casks.
7. Treat applications as shared unless Fausto uses a local or skip command;
   keep formulae local unless deliberately added to `packages.txt`.
8. Only entries explicitly recorded in `retired-apps.tsv` may cause app
   removal during sync.
9. `mac-app` may commit and push its own manifest targets; leave unrelated
   commits and pushes manual.

For every custom keybinding change:

1. Update `~/.config/keymaps/registry.tsv`, preserving unique IDs.
2. Update the relevant VS Code, Karabiner, Ghostty, Herdr, or Neovim
   configuration and include its `km:<id>` marker (Neovim uses the ID in its
   mapping helper).
3. Keep modifier roles consistent with the Keyboard Layers section.
4. Run `~/.config/keymaps/keymap-docs` to regenerate the table in this file.
5. Run `~/.config/keymaps/keymap-docs --check` and relevant configuration tests.

Do not add an undocumented binding, reuse a key in one layer, or assign a
modifier a new role without explicit approval.

For periodic sync maintenance:

1. Run `sync-maintain`.
2. Inspect `bare status` and relevant diffs.
3. Report installations and any one-time permissions still needed.
4. Ask before running `bcp`.

For a new Mac, verify `bare pull --ff-only` and `bare status`, run the installer
and maintenance script, then report missing manual sign-ins and permissions.

## Maintenance Checks

Use these after changing the setup:

```fish
keymap-docs --check
bash -n ~/.local/bin/mac-app ~/.local/bin/mac-sync ~/.config/sync/*.sh
jq empty ~/.config/karabiner/karabiner.json
plutil -lint ~/.config/mac-setup/com.fausto.mac-sync.plist
mac-sync --no-pull
herdr config check
fish --no-execute ~/.config/fish/config.fish
```

Some health output is informational. Report exact failures instead of hiding
them. Keep the setup small: add a plugin or tool only when it removes recurring
friction that existing tools cannot solve clearly.
