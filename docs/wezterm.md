# WezTerm

[← Back to the index](../CLAUDE.md)

`wezterm/wezterm.lua`. One file, no config splitting, because it's a terminal and it doesn't need
a module system.

The whole point of the keybinds here is muscle memory. Tabs, panes, and copy mode all mirror what
the same action does in [Emacs](emacs.md) and [Neovim](nvim.md), so `C-S-h/j/k/l` moves between
panes the same way `C-h/j/k/l` moves between windows in the editors.

## Tabs

| Key | Action |
|-----|--------|
| `C-←` / `C-→` | Previous / next tab |
| `C-S-t` | New tab |
| `C-S-w` | Close tab (confirms) |
| `C-S-n` | Rename tab |
| `C-S-1` … `C-S-9` | Jump to tab by number |

On macOS the native `CMD` versions all work too: `CMD-t`, `CMD-w`, `CMD-n`, `CMD-[` / `CMD-]`,
`CMD-1` through `CMD-9`, `CMD-S-z`.

## Panes

| Key | Action |
|-----|--------|
| `C-S-\` | Split right |
| `C-S--` | Split down |
| `C-S-h/j/k/l` | Move focus |
| `C-S-H/J/K/L` | Resize by 5 |
| `C-S-z` | Zoom / unzoom |
| `C-S-x` | Close pane (confirms) |

## Copy mode

`C-S-[` to enter. Inside, it's evil normal mode:

| Key | Action |
|-----|--------|
| `h/j/k/l` | Move |
| `w` / `e` / `b` | Word forward / word end / word back |
| `0` / `$` | Line start / end |
| `g` / `G` | Top / bottom of scrollback |
| `C-f` / `C-b` | Page down / up |
| `v` / `V` / `C-v` | Character / line / block selection |
| `y` | Yank and exit |
| `q` or `Esc` | Exit |

Yank copies to both the clipboard and the primary selection.

## Everything else

| Key | Action |
|-----|--------|
| `Shift-PageUp/Down` | Scroll a page |
| `Alt-k` / `Alt-j` | Scroll 3 lines |
| `C-=` / `C--` / `C-0` | Font bigger / smaller / reset |
| `C-S-f` | Search scrollback |
| `C-S-p` | Command palette |
| `C-S-r` | Reload config |

## Shift+Enter for TUIs

```lua
{ key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b\r' },
```

This one needs an explanation. WezTerm sends a plain CR for Shift+Enter by default, which is
byte-identical to Enter, so Claude Code and other TUIs can't tell them apart and submit instead of
inserting a newline. Sending Meta+Enter (`ESC CR`) instead gives them something distinguishable to
map. `SendString` writes straight to the pane, so it dodges WezTerm's built-in `ALT+Enter`
fullscreen binding.

## Appearance

doom-one palette, defined as a `C` table at the top and applied to `colors`, the tab bar, and both
custom status handlers. The tab bar is the hand-rolled kind (`use_fancy_tab_bar = false`) with
powerline separators, which is why a Nerd Font is a hard requirement here. Without one the
separators render as tofu.

Font stack is JetBrainsMono Nerd Font, falling back to JetBrains Mono, then Fira Code, then
Symbols Nerd Font Mono. Lucida Console gets prepended on Windows only, omitted elsewhere so it
doesn't spew load warnings. Italics get their own `font_rules` entry so comments and keywords
render italic the same way they do in Emacs.

The right status bar shows the active key table (when one is active), the short hostname, and the
time, each in its own powerline segment.

## Platform branches

**Windows** gets a `gui-startup` handler that sizes the window to 85% of the active screen and
centers it. The old fixed `initial_cols` / `initial_rows` opened a window bigger than the screen on
some displays. mac and Linux keep the generous fixed size (220x50).

**Windows opens into WSL2**, because these dotfiles are unix:

```lua
config.wsl_domains = wezterm.default_wsl_domains()
config.default_domain = 'WSL:Ubuntu'
```

`default_wsl_domains()` auto-discovers installed distros and names each one `WSL:<distro>`. WezTerm
stays a native Windows GUI app driving a real Linux pty, so fonts, clipboard, GPU rendering, and
every keybind above work unchanged. It prefers `WSL:Ubuntu`, falls back to the first distro it
finds, then to Nushell, pwsh, and built-in powershell when there's no WSL at all. WezTerm has no
`which` helper, so `find_in_path` scans `PATH` manually for those.

The config file itself stays on the **Windows** side, since WezTerm is a Windows app. See
[WINDOWS-MIGRATION.md](../WINDOWS-MIGRATION.md).

**macOS** gets `INTEGRATED_BUTTONS|RESIZE` decorations and background blur. Everything else gets
`TITLE|RESIZE`.

## Changing the theme

Replace the values in the `C` table, or point `colors.scheme` at a
[built-in WezTerm scheme](https://wezfurlong.org/wezterm/colorschemes/index.html) and delete the
manual `colors` block. If you do, remember [starship](starship.md) and the fzf colors in
[zsh](zsh.md) hardcode the same palette.
