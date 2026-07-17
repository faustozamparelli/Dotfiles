# Fausto's Terminal Workspace Manual

This is the single human and agent manual for this dotfiles setup. It explains
the working model, the custom keymaps, the terminal tools already installed,
and the rules for safely changing or synchronizing the configuration.

The intended workspace is:

```text
macOS
└── Ghostty                 terminal renderer
    └── tmux                persistent windows and panes
        ├── Neovim          editing, files, search, Git, and language tools
        ├── Codex           agent pane
        └── fish            occasional shell commands
```

The goal is not to memorize every Unix command. Spend most of the day in
Neovim, let tmux organize long-lived work, and use the shell when it is the
clearest tool for a short operation.

## Start Here

Open Ghostty. Its fish configuration automatically attaches to the persistent
tmux session named `default`. Work survives accidental terminal-window closes.

The essential loop is:

1. Use `z <project-name>` to jump to a known project.
2. Run `n .` to open that directory in Neovim.
3. Use `Space e` or `-` to browse with Oil.
4. Use `Space f f` to find a file and `Space f g` to search its contents.
5. Use `Space f a` to jump to a file or project outside the current project.
6. Press `Cmd-g` when an agent is useful.
7. Use `Cmd-b` or `Cmd-n` only when another shell pane is genuinely needed.
8. Press `Ctrl-Space ?` for searchable custom-keymap help.

An example:

```fish
z my-project
n .
```

Inside Neovim, `:pwd` shows the directory used by file search, text search,
Git commands, and newly opened terminal processes.

## The Mental Model

### Ghostty is only the outer window

Ghostty displays the terminal. It deliberately does not own tabs or splits;
those default shortcuts are disabled because tmux owns the workspace layout.
Closing Ghostty does not end the tmux session.

### tmux owns workspaces

A tmux session contains windows, and each window contains panes:

```text
session: default
├── window 1: project-a
│   ├── pane: Neovim
│   └── pane: Codex
└── window 2: project-b
    ├── pane: Neovim
    └── pane: shell
```

Use one tmux window per project. A pane is a temporary view within that
project, not a substitute for a project. New panes and windows inherit the
current pane's directory.

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
n .
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

- `Ctrl-h/l`: move between tmux sessions.
- `Cmd`: frequent tmux window operations.
- `Alt`: directional tmux pane focus; adding Shift resizes.
- `Space`: discoverable Neovim operations grouped by category.
- `Ctrl-Space`: tmux administration and infrequent operations.
- Other `Ctrl` keys retain conventional terminal and editor behavior.

The notation `Ctrl-Space c` means press `Ctrl-Space`, release it, then press
`c`. The notation `Cmd-g` means hold Command while pressing `g`.

## Custom Keymap Reference

This table is generated from `~/.config/keymaps/registry.tsv`. Agents must
update the registry and implementation together, then run `keymap-docs`.

<!-- KEYMAPS:START -->
| Layer | Category | Key | Behavior |
|---|---|---|---|
| Ghostty | Command | `Cmd-a` | Leave the current editing mode |
| tmux | Command | `Cmd-h` | Select the previous window |
| tmux | Command | `Cmd-l` | Select the next window |
| tmux | Command | `Cmd-Shift-h` | Move the current window left |
| tmux | Command | `Cmd-Shift-l` | Move the current window right |
| tmux | Command | `Cmd-b` | Create a pane on the right |
| tmux | Command | `Cmd-n` | Create a pane below |
| tmux | Command | `Cmd-g` | Create or focus the Codex pane |
| tmux | Command | `Cmd-w` | Close the current pane |
| tmux | Control | `Ctrl-h` | Switch to the previous session |
| tmux | Control | `Ctrl-l` | Switch to the next session |
| tmux | Alt | `Alt-h` | Focus the pane to the left |
| tmux | Alt | `Alt-j` | Focus the pane below |
| tmux | Alt | `Alt-k` | Focus the pane above |
| tmux | Alt | `Alt-l` | Focus the pane to the right |
| tmux | Alt | `Alt-Shift-h` | Resize the pane left |
| tmux | Alt | `Alt-Shift-j` | Resize the pane down |
| tmux | Alt | `Alt-Shift-k` | Resize the pane up |
| tmux | Alt | `Alt-Shift-l` | Resize the pane right |
| tmux | Ctrl-Space | `c` | Create a tmux window |
| tmux | Ctrl-Space | `n` | Create and switch to a named session |
| tmux | Ctrl-Space | `s` | Choose a tmux session |
| tmux | Ctrl-Space | `W` | Choose a tmux window |
| tmux | Ctrl-Space | `w` | Kill the current session after confirmation |
| tmux | Ctrl-Space | `d` | Detach the tmux client |
| tmux | Ctrl-Space | `r` | Reload tmux configuration |
| tmux | Ctrl-Space | `S` | Save a session snapshot |
| tmux | Ctrl-Space | `R` | Restore a session snapshot |
| tmux | Ctrl-Space | `?` | Open searchable keymap help |
| Neovim | Space | `Space Space` | Save the current file |
| Neovim | Space | `Space e` | Open Oil file browser |
| Neovim | Direct | `-` | Open the parent directory in Oil |
| Neovim | Space | `Space f f` | Find files |
| Neovim | Space | `Space f a` | Find files or projects across working roots |
| Neovim | Space | `Space f g` | Search project text |
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
<!-- KEYMAPS:END -->

## tmux in Practice

### Sessions

The far-left status strip shows the previous session, the emphasized current
session, and the next session. With only one session it shows only the current
name; with two it shows the other session once.

- `Ctrl-h` switches to the previous session alphabetically.
- `Ctrl-l` switches to the next session alphabetically.
- `Ctrl-Space n` asks for a name, then creates and switches to that session.
- `Ctrl-Space w` asks for confirmation, then kills the current session.
- `Ctrl-Space s` remains available when a searchable overview is clearer.
- `Ctrl-Space W` opens the window chooser.

### Windows and panes

- `Cmd-h` and `Cmd-l` move between project windows.
- `Cmd-Shift-h` and `Cmd-Shift-l` reorder the current window.
- `Cmd-b` creates a pane on the right.
- `Cmd-n` creates a pane below.
- `Cmd-w` closes the active pane.
- `Alt-h/j/k/l` moves spatially between panes.
- `Alt-Shift-h/j/k/l` resizes the active pane.

The current session is shown at the upper left of the tmux status line. The
active window has a purple dot in the centered window list.

### The agent pane

`Cmd-g` creates a Codex pane on the right using 40% of the current window. It
starts in the current pane's directory. Pressing `Cmd-g` again focuses the
existing agent pane instead of creating duplicates.

Before opening it, make sure the Neovim/shell pane belongs to the correct
project. Give the agent paths and constraints explicitly. For dotfiles or Mac
setup work, say:

```text
Read ~/.config/sync/README.md first and follow its agent contract.
```

### Sessions and recovery

- `Ctrl-Space d` detaches without ending programs.
- `Ctrl-Space s` opens the session chooser.
- `Ctrl-Space S` saves a tmux-resurrect snapshot.
- `Ctrl-Space R` restores the latest snapshot.
- `Ctrl-Space r` reloads the tmux configuration after an edit.

Detach when leaving work running. Close individual panes with `Cmd-w`. Avoid
typing `exit` into a pane unless ending that shell or process is intentional.

### Copy mode

tmux has mouse support and vi-style copy mode. Enter copy mode with
`Ctrl-Space [`; move with Vim keys, press `Space` to begin a selection, and
press `Enter` to copy it. Press `q` to leave copy mode. The terminal history
limit is 100,000 lines.

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
- `Space f g`: text inside files using ripgrep.
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

Use tmux panes for independent processes and Neovim windows for simultaneous
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

Python uses Pyright and Ruff. C/C++ uses clangd. Supported files format before
save.

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
n          nvim
l / ls     eza -a --git
b          bat
o          open
cl         clear
fi         yazi
py         uv run python
python     uv run python
sv         activate .venv for fish
nb         jupyter notebook
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

The `python` and `py` aliases run `uv run python`, allowing uv to use the
project environment. Typical commands:

```fish
uv init
uv add package-name
uv add --dev pytest ruff
uv run python script.py
uv run pytest
uv sync
```

Use a project's declared dependencies instead of installing packages globally.

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
n .
```

Then use `Space f f`, `Space f g`, and `Space f b`. Press `Cmd-g` if the task
benefits from an agent.

### Work on two projects

1. Open the first project and Neovim.
2. Press `Ctrl-Space c` to create another tmux window inheriting the current
   path.
3. Use `z other-project`, then `n .`.
4. Switch projects with `Cmd-h` and `Cmd-l`.

### Inspect a change before committing

```fish
git status
git diff
git diff --check
```

Run the project's tests, stage intentional paths, inspect `git diff --staged`,
then commit.

### Recover the workspace

Reopen Ghostty; it attaches to the existing `default` tmux session. If the
machine restarted, press `Ctrl-Space R` to restore the latest explicitly saved
snapshot.

### Edit this setup

```fish
n ~/.config
```

Use `Space f f` to locate the relevant configuration. After keymap changes run:

```fish
keymap-docs
keymap-docs --check
```

After tmux changes press `Ctrl-Space r`. Restart Neovim after plugin or startup
changes. Ghostty reload behavior depends on the setting changed; reopening it
is the reliable option.

## Mac Synchronization

This folder keeps the MacBook Air and MacBook Pro aligned through the bare
dotfiles repository. Run:

```fish
sync-maintain
```

The script:

- pulls the bare dotfiles repository with `--ff-only`;
- refreshes this Mac's inventory under `inventory/<mac-name>/`;
- reconciles editable software choices in `software-<mac-name>.txt`;
- installs missing shared Homebrew packages, casks, and App Store apps;
- keeps retired VS Code configuration and extension names as reference-only dotfiles;
- exports/applies manually added macOS App Shortcuts;
- tracks Marta's portable settings; and
- stages tracked sync and dotfile paths without committing or pushing.

An empty live App Shortcuts dictionary does not replace a nonempty shared
mapping; maintenance restores the shared mapping instead. To intentionally
clear every shortcut for a domain, edit its shared plist explicitly.

`software-<mac-name>.txt` is the editable source of truth. Files under
`shared/`, `inventory/`, and `state/` are generated or observed state. New
software defaults to local. Move `[.]` between the `shared` and `local`
brackets, then run `sync-maintain` again:

```text
# type  item       shared  local
cask    marta      []      [.]
```

`bcp` runs maintenance, stages tracked dotfiles, asks for a commit message, and
pushes. Inspect `bare status` and relevant diffs first.

Maintenance also stages user-authored Codex skill directories and the custom
stealth launcher, mode, profile, and theme. It deliberately does not track
`~/.codex/config.toml`, authentication, bundled system skills, plugin caches,
sessions, histories, databases, or generated application state. Codex and the
ChatGPT application may manage some of that state themselves; it is not part
of this dotfiles contract.

### New Mac

1. Follow the root dotfiles bootstrap instructions until the bare repository
   exists.
2. Run `~/.config/sync/install-agent.sh`.
3. Sign into an agent application.
4. Tell the agent to read this file and finish the new-Mac procedure.
5. Handle manual sign-ins, licenses, and macOS privacy permissions.

The untracked tmux-resurrect runtime belongs under
`~/.local/share/tmux/plugins`; only its configuration belongs in dotfiles.

## Agent Contract

Agents working on this setup must follow these rules:

1. Read this entire file before changing dotfiles, Mac synchronization,
   Ghostty, tmux, Neovim, fish, or keymaps.
2. Use the bare dotfiles repository; do not recreate tracked configuration.
3. Preserve the architecture: Ghostty renders, tmux owns workspaces, Neovim
   owns editing, and fish supplies short commands.
4. Keep this as the only Markdown file under `~/.config`. Update it instead of
   adding repository-specific agent or README files.
5. Do not sync secrets, tokens, browser profiles, histories, caches, keychains,
   databases, or machine-local state.
6. Prefer Homebrew for packages and casks.
7. Ask Fausto before changing software from local to shared.
8. Never add a removal bucket or uninstall software from the sync script.
9. Leave commit and push manual unless Fausto explicitly requests them.

For every custom keybinding change:

1. Update `~/.config/keymaps/registry.tsv`, preserving unique IDs.
2. Update the relevant Ghostty, tmux, or Neovim configuration and include its
   `km:<id>` marker (Neovim uses the ID in its mapping helper).
3. Keep modifier roles consistent with the Keyboard Layers section.
4. Run `~/.config/keymaps/keymap-docs` to regenerate the table in this file.
5. Run `~/.config/keymaps/keymap-docs --check` and relevant configuration tests.

Do not add an undocumented binding, reuse a key in one layer, or assign a
modifier a new role without explicit approval.

For periodic sync maintenance:

1. Run `sync-maintain`.
2. Ask which local software should become shared.
3. Move only approved `[.]` markers in `software-<mac-name>.txt`.
4. Run `sync-maintain` and `bare status` again.
5. Report installations, promotions, and remaining local software.
6. Ask before running `bcp`.

For a new Mac, verify `bare pull --ff-only` and `bare status`, run the installer
and maintenance script, then report missing manual sign-ins and permissions.

## Maintenance Checks

Use these after changing the setup:

```fish
keymap-docs --check
bash ~/.config/sync/tests/test-maintain.sh
nvim --headless '+checkhealth' '+qa'
tmux source-file ~/.config/tmux/tmux.conf
fish --no-execute ~/.config/fish/config.fish
```

Some health output is informational. Report exact failures instead of hiding
them. Keep the setup small: add a plugin or tool only when it removes recurring
friction that existing tools cannot solve clearly.
