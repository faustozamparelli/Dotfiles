# Fausto's Neovim configuration

This is a small, native-first Neovim setup for Python, C/C++, Markdown,
project navigation, and Git. It uses Neovim's built-in package manager,
LSP client, completion, diagnostics, and Tree-sitter APIs. There is no
`nvim-lspconfig`, `nvim-cmp`, or `blink.cmp` layer.

The installed Neovim at the time this guide was written is 0.12.5.

## Key notation and first steps

The leader key is Space. For example, `<leader>ff` means press Space, then
`f`, then `f`. The local leader is also Space.

- Normal mode is the main navigation mode. Press `Esc` to return to it.
- Press `i` to insert before the cursor and `a` to insert after it.
- Press `v` for character-wise selection or `V` for line-wise selection.
- Press `:` to run a command, `/` to search forward, and `?` to search
  backward.
- Save with Space Space. Undo with `u`; redo with `U`.
- Press `<leader>?` at any time to see the leader-key menu.

Useful built-in commands include `:help topic`, `:checkhealth`, `:messages`,
`:LspInfo`, `:copen`, `:cnext`, and `:cprev`.

## Everyday workflow

1. Find a project or file with `<leader>fa` or `<leader>ff`.
2. Edit normally. Completion appears automatically when an attached language
   server has suggestions; press `Tab` to accept the selected or first item.
3. Inspect a symbol with `K`, jump to it with `gd`, or find its usages with
   `gr`.
4. Save with `<leader><leader>`. Python and C/C++ files are formatted before
   they are written.
5. Review changed lines with `<leader>gs`, `<leader>gn`, and `<leader>gp`.

## All custom shortcuts

### Files, search, and help

| Mode | Key | What it does | How to use it |
| --- | --- | --- | --- |
| Normal | `<leader><leader>` | Saves the current file | Press Space twice. |
| Normal | `<leader>e` | Opens Oil at the current location | Navigate the filesystem as an editable buffer. |
| Normal | `-` | Opens the parent directory in Oil | Use repeatedly to move upward. |
| Normal | `<leader>ff` | Finds files under the current working directory | Type part of a path, move through results, then press Enter. |
| Normal | `<leader>fa` | Finds files, directories, and external documents across configured locations | Select a directory to switch to it, a text file to edit it, or another file to open it with macOS. |
| Normal | `<leader>fg` | Searches the current project by text | Type text or a regular expression, select a result, and press Enter. |
| Normal | `<leader>fb` | Finds an open buffer | Select a buffer and press Enter. |
| Normal | `<leader>fr` | Finds a recently opened file | Select a path and press Enter. |
| Normal | `<leader>fh` | Searches Neovim help | Search for an option, command, or concept and press Enter. |
| Normal | `<leader>fF` | Reveals the current file in macOS Finder | Use while editing a real file. |
| Normal | `<leader>d` | Replaces or deletes every whitespace-delimited WORD containing the last search match | First search with `/pattern`. Then press `<leader>d` and enter the replacement; submit an empty replacement to delete the matching WORDs. |
| Any listed mode | `Esc` | Leaves the current mode and clears highlighted search matches | The search pattern remains available to `n`, `N`, and `<leader>d`. |

`<leader>fa` searches these roots recursively:

- `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/ShortTerm`
- `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/LongTerm`
- `~/Developer`
- `~/.config`

It skips `.git`, `.venv`, `__pycache__`, `build`, `dist`, `node_modules`, and
`target`. It also shows the immediate children of the home directory without
recursively walking all of `~/Library`. Editable MIME types open in Neovim;
other files use the system application. Opening a directory changes Neovim's
working directory, adds it to zoxide when available, and opens it through Oil.

### Language intelligence

These actions need an LSP server attached to the current buffer. Put the cursor
on the symbol before using a normal-mode navigation shortcut.

| Mode | Key | What it does | How to use it |
| --- | --- | --- | --- |
| Insert | `Tab` | Accepts completion | If the menu has no selected row, it accepts the first suggestion; otherwise it accepts the selected row. It inserts a literal tab when the menu is closed. |
| Insert/Select | `Ctrl-S` | Shows signature help | Use after typing `function(` or while moving between its arguments. This is a Neovim built-in LSP mapping. |
| Normal | `K` | Shows hover documentation and type information | Press it again while the popup is open to focus the popup and scroll it. |
| Normal | `<leader>lh` | Shows a much larger hover window | Use for documentation that is cramped in the normal `K` popup. |
| Normal | `gd` | Opens the symbol's definition | Multiple results are put in the quickfix list; the first opens in the current window. Use `:cnext`, `:cprev`, or `:copen` for the rest. |
| Normal | `gi` | Opens the symbol's implementation | Useful for interfaces and abstract declarations. Pyright can still lead to a `.pyi` stub when that is the information it owns. |
| Normal | `gy` | Opens the symbol's type definition | For a variable, this goes to the declaration of its type rather than to where the variable was assigned. |
| Normal | `gr` | Finds references with fzf-lua | Search and select every place that uses the symbol. |
| Normal | `gs` | Lists symbols in the current file | Browse classes, functions, methods, and other document symbols. |
| Normal | `<leader>ls` | Searches symbols across the LSP workspace with fzf-lua | Type part of a class, function, or symbol name, then press Enter. This searches indexed symbols, not arbitrary source text. |
| Normal/Visual | `<leader>la` | Requests code actions | Use for server-offered fixes, refactors, and import actions. In Visual mode it applies to the selection. |
| Normal | `<leader>lr` | Renames a symbol across the project | Enter the new name and confirm. Review the resulting edits. |
| Normal/Visual | `<leader>lf` | Formats the current buffer or selection | The call is synchronous and times out after three seconds. |
| Normal | `<leader>ld` | Opens workspace diagnostics in fzf-lua | Search and jump among diagnostics reported by attached servers. |
| Normal | `<leader>le` | Copies every error diagnostic to the system clipboard | The copied text includes relative file, line, column, source, and message. Warnings are intentionally excluded. |
| Normal | `<leader>lE` | Opens every error diagnostic in the quickfix window | Press Enter on an error to jump to it; use `:cnext`, `:cprev`, or `:cclose` to navigate or close the list. |
| Normal | `<leader>lp` | Opens the real Python source for the expression under the cursor | Use on `requests.get`, an imported alias such as `Path`, or another Python object. It opens the `.py` file at the implementation line when inspectable. |

### Python discovery and real-source workflow

Completion is powered by Neovim's native completion UI and Pyright. It is
automatically triggered in Python buffers. Use `Ctrl-N` and `Ctrl-P` to move
through the native popup, `Tab` to accept, or `Ctrl-E` to dismiss it.

To discover APIs from a known module, type a dot and wait for completion:

```python
pathlib.
```

Pyright auto-import completion is enabled explicitly. If you type `Path` and
choose the `pathlib.Path` suggestion, Pyright can insert this automatically:

```python
from pathlib import Path
```

A practical inspection sequence is:

```text
Discover a name       completion, <leader>ls, or <leader>fg
Read its docs/type    K
See its arguments     Ctrl-S inside the call
Add/fix an import     completion or <leader>la
Open its definition   gd
Find implementations gi
Open runtime .py code <leader>lp
```

`gd` and `gi` ask the language server, so Pyright may correctly return a type
stub. `<leader>lp` is a separate runtime lookup. It reads absolute import
statements from the current buffer, understands common aliases such as
`import requests as r` and `from pathlib import Path`, imports the target with
Python, and uses `inspect` to locate its source file and starting line.

The Python interpreter is selected in this order:

1. The nearest `.venv/bin/python` above the current file.
2. `$VIRTUAL_ENV/bin/python`.
3. `python3`, then `python`, from `$PATH`.

Runtime lookup has limits. Importing a package can execute that package's
normal import-time code. Relative imports and dynamically created objects may
not resolve. Built-ins such as `bytearray`, `list`, and `dict`, plus compiled
extension functions, have no Python `.py` implementation to open; their real
implementation is C or another compiled language. Use CPython's source tree
for those.

### Git

| Mode | Key | What it does |
| --- | --- | --- |
| Normal | `<leader>gs` | Opens Git status in fzf-lua. |
| Normal | `<leader>gb` | Shows blame information for the current line. |
| Normal | `<leader>gd` | Diffs the current file against the index. |
| Normal | `<leader>gn` | Moves to the next changed hunk. |
| Normal | `<leader>gp` | Moves to the previous changed hunk. |

Gitsigns adds Git change information to buffers. Continuous inline blame is
disabled; blame appears only when requested.

### Markdown

| Mode | Key or gesture | What it does |
| --- | --- | --- |
| Normal | `<leader>mp` | Toggles rendered Markdown in the current buffer. |
| Normal | `<leader>mb` | Saves the current Markdown file and opens it in the macOS Helium application. |
| Visual | Finish a character- or line-wise selection | Toggles a persistent yellow highlight over the selected Markdown text. |
| Visual/mouse | Release the left mouse button after selecting | Toggles a persistent Markdown highlight. |
| Normal/mouse | Right-click a highlight | Removes the persistent highlight under the pointer. |

Persistent highlights are a custom feature, separate from Markdown syntax.
Selecting exactly the same range again removes it, while overlapping ranges
are merged. Blockwise selections are not supported. Highlights are restored
per file and saved as JSON below:

```text
stdpath("data")/markdown-highlights/
```

On the usual macOS setup that is below `~/.local/share/nvim/`. The storage
filename is a hash of the Markdown file's normalized absolute path.

render-markdown.nvim styles headings, bullets, checkboxes, fenced code, and
inline code. Its custom palette follows the editor's light or dark appearance.

### Herdr terminal tabs and panes

These mappings control Herdr's terminal layout; they do not create Neovim tab
pages or Neovim splits.

| Mode | Key | What it does |
| --- | --- | --- |
| Normal | `<leader>ac` | Creates and focuses a new Herdr tab, starts Codex there, and uses the current file's folder or the directory shown by Oil. |
| Normal | `Cmd-B` or `<leader>pv` | Creates and focuses a Herdr pane to the right, inheriting the current file or Oil directory. |
| Normal | `Cmd-N` or `<leader>ph` | Creates and focuses a Herdr pane below, inheriting the current file or Oil directory. |
| Normal | `Alt-H/J/K/L` | Moves through Neovim windows first; at an outer edge, continues into the adjacent Herdr pane. |

`Cmd-H` and `Cmd-L` remain Herdr's previous/next-tab shortcuts. They are not
redefined by Neovim.

### Buffers, windows, and editing

| Mode | Key | What it does |
| --- | --- | --- |
| Normal | `<leader>bl` | Goes to the next buffer. |
| Normal | `<leader>bh` | Goes to the previous buffer. |
| Normal | `<leader>bd` | Deletes the current buffer. Unsaved changes trigger confirmation. |
| Normal/Visual/Operator | `H` | Moves to the first nonblank character of the line. |
| Normal/Visual/Operator | `L` | Moves to the end of the line. |
| Normal | `U` | Redoes the last undone change. |
| Visual | `J` | Moves the selected lines down and reindents them. |
| Visual | `K` | Moves the selected lines up and reindents them. |
| Normal | `<leader>rr` | Restarts Neovim and reloads the configuration. |
| Normal | `<leader>qq` | Quits the current window. |
| Normal | `<leader>qa` | Quits all Neovim windows. |
| Normal | `<leader>?` | Immediately displays the which-key leader menu. |

## Packages

Packages are declared in `lua/fausto/plugins.lua` and installed with the native
`vim.pack` package manager.

| Package | Purpose | Configuration here |
| --- | --- | --- |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | Filesystem editing | Replaces the default file explorer, shows hidden files, and moves deleted items to Trash. Simple edits still ask for confirmation. |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | Fuzzy finding | Powers file, buffer, help, grep, Git, diagnostic, reference, workspace-symbol, and custom anywhere searches. Uses a large window with a vertical preview. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax parsing, highlighting, and indentation | Parsers are installed for Bash, C, C++, Fish, JSON, Lua, Markdown, Python, TOML, TSV, Vim, Vimdoc, and YAML. The Bash parser is reused for `sh`. |
| [treesitter-parser-registry](https://github.com/neovim-treesitter/treesitter-parser-registry) | Tree-sitter parser metadata | Tracks the parser definitions used by nvim-treesitter. |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git changes inside buffers | Provides status, blame, diff, and hunk movement integrations. |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding discovery | Uses the Helix-style layout, opens automatically after 250 ms, and groups leader mappings by purpose. |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Rich Markdown rendering | Renders headings, code, bullets, and checkboxes with this configuration's restrained palette. |

To update all managed packages, run:

```vim
:lua vim.pack.update()
```

Neovim opens a confirmation view before applying updates unless forced. Run
`:checkhealth` after updating if behavior changes.

## Language servers and external programs

The package manager does not install language servers or command-line tools.
They must be available separately on `$PATH`.

| Program | Used for | Required? |
| --- | --- | --- |
| `pyright-langserver` | Python completion, auto-imports, types, hover, navigation, references, and diagnostics | Required for Python LSP features. |
| `ruff` | Python linting and formatting through Ruff's language server | Required for Ruff diagnostics/formatting. |
| `clangd` | C, C++, Objective-C, Objective-C++, and CUDA language intelligence | Required for those filetypes. |
| `fzf` | Interactive fuzzy selection | Required by fzf-lua. |
| `file` | MIME detection in the anywhere picker | Required for correct text-versus-external opening. |
| `zoxide` | Records directories selected in the anywhere picker | Optional. |
| `open` | Finder reveal, external documents, and Helium integration | macOS feature. |
| `herdr` | Renames tabs, creates terminal panes, and opens Codex in a dedicated Herdr tab | Optional; these integrations are active only when Neovim runs inside Herdr. |
| `Helium` | External Markdown viewing | Optional; needed only for `<leader>mb`. |

Pyright uses basic type checking. Ruff and Pyright attach to Python. clangd runs
with background indexing and clang-tidy enabled. Project roots are detected
from normal files such as `pyproject.toml`, Ruff configuration, compilation
databases, and `.git`.

Only error-level diagnostics are drawn as signs, underlines, virtual text, and
floating diagnostics. This keeps warnings visually quiet, although they still
exist in the diagnostic collection and may appear in `<leader>ld`.

## Automatic behavior

- Yanked text flashes briefly.
- A modified real file is saved when Neovim loses focus.
- Python, C, and C++ buffers are synchronously formatted before every save.
- Native LSP completion is enabled with automatic triggering whenever the
  attached server supports completion.
- New splits open below and to the right.
- Search ignores case unless the pattern contains an uppercase letter.
- Substitution previews appear in a split.
- Persistent undo is enabled.
- The cursor line, absolute line number, relative line numbers, and a permanent
  sign column are visible.
- Tabs expand to two spaces; indentation and tab display width are two columns.
- Invisible tabs, trailing spaces, and nonbreaking spaces are shown.
- The system clipboard is used for normal yank/delete/put registers.
- The mouse is enabled and long lines wrap.
- Commands with unsaved changes ask for confirmation when possible.

On macOS, the theme checks system appearance every two seconds. Dark mode uses
`habamax`; light mode uses `morning`. Both receive custom backgrounds, subtle
cursor lines, cyan accents, rounded floating-window borders, Markdown colors,
and persistent-highlight colors. On other systems, the current Neovim
background setting determines the initial appearance.

When running inside Herdr (`HERDR_ENV=1` with `HERDR_TAB_ID` set), entering a
buffer or changing directory renames the Herdr tab to match the current file or
directory.

## Configuration layout

```text
init.lua                         load order and leader keys
lua/fausto/options.lua           editor options
lua/fausto/theme.lua             adaptive macOS theme and highlights
lua/fausto/plugins.lua           packages and package configuration
lua/fausto/lsp.lua               diagnostics, servers, and native completion
lua/fausto/keymaps.lua           custom shortcuts
lua/fausto/autocmds.lua          save, format, yank, and Herdr automation
lua/fausto/workspace.lua         cross-workspace anywhere picker
lua/fausto/python_source.lua     real Python source resolver
lua/fausto/markdown_highlights.lua persistent Markdown selections
```

The modules load in the order shown by `init.lua`: options, theme, plugins,
LSP, keymaps, general autocommands, then persistent Markdown highlights.

## Troubleshooting

- Run `:checkhealth` for general, provider, Tree-sitter, and plugin checks.
- Run `:LspInfo` inside a source file to see which servers attached and what
  project root they selected.
- If Python imports or `<leader>lp` use the wrong environment, start Neovim
  with the correct virtual environment active or add a `.venv` to the project.
- If completion does not appear, confirm that an LSP is attached with
  `:LspInfo`; native keyword completion can still be opened with `Ctrl-N`.
- If `gd`, `gi`, or `gy` has several destinations, use `:copen` to inspect the
  quickfix list.
- If a shortcut is forgotten, press `<leader>?`, or search mappings with
  `:map`, `:nmap`, `:imap`, or `:verbose map {key}`.
- If formatting blocks a save, check `:messages` and the relevant server.
- If `<leader>lp` reports that only compiled code is available, the object has
  no inspectable Python implementation; consult the package's native source.
