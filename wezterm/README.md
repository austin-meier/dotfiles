# WezTerm Config

DOOM Emacs-inspired WezTerm configuration. doom-one color scheme, Lucida Console font, vi copy mode, and tab/pane management that mirrors DOOM keybindings.

## Requirements

- [WezTerm](https://wezfurlong.org/wezterm/) (nightly or stable ≥ 20240203)
- A [Nerd Font](https://www.nerdfonts.com/) — JetBrainsMono Nerd Font recommended for powerline tab separators. Without one the tab bar falls back to plain text.

## Tabs

| Key | Action |
|-----|--------|
| `C-←` / `C-→` | Previous / next tab |
| `C-S-t` | New tab |
| `C-S-w` | Close tab (with confirm) |
| `C-S-n` | Rename current tab |
| `C-S-1` … `C-S-9` | Jump to tab by number |

On macOS, `CMD` aliases exist for all of the above (`CMD-t`, `CMD-w`, `CMD-[`/`CMD-]`, `CMD-1`…`CMD-9`).

## Panes

| Key | Action |
|-----|--------|
| `C-S-\` | Split pane right (vertical split) |
| `C-S--` | Split pane down (horizontal split) |
| `C-S-h/j/k/l` | Navigate panes (left/down/up/right) |
| `C-S-H/J/K/L` | Resize pane in that direction |
| `C-S-z` | Zoom / unzoom current pane |
| `C-S-x` | Close current pane (with confirm) |

## Copy Mode (vi/evil)

Enter with `C-S-[`. Behaves like evil normal mode.

| Key | Action |
|-----|--------|
| `h/j/k/l` | Move cursor |
| `w / e / b` | Word forward / word-end / word back |
| `0 / $` | Start / end of line |
| `g / G` | Top / bottom of scrollback |
| `C-f / C-b` | Page down / page up |
| `v` | Character selection |
| `V` | Line selection |
| `C-v` | Block selection |
| `y` | Yank selection and exit |
| `q` / `Escape` | Exit copy mode |

## Scrollback

| Key | Action |
|-----|--------|
| `Shift-PageUp/Down` | Scroll by page |
| `Alt-k / Alt-j` | Scroll by 3 lines |

## Font Size

| Key | Action |
|-----|--------|
| `C-=` | Increase font size |
| `C--` | Decrease font size |
| `C-0` | Reset font size |

## Search & Utilities

| Key | Action |
|-----|--------|
| `C-S-f` | Search scrollback |
| `C-S-p` | Command palette |
| `C-S-r` | Reload config |

## Fonts

Primary font is **Lucida Console** (matches the Emacs config). Nerd Font variants are loaded as fallbacks for tab bar glyphs. To swap the primary font, edit the `font_with_fallback` table near the top of `wezterm.lua`.

## Colors

Full doom-one palette. To switch themes, replace the `C` table values or point `colors.scheme` at any [built-in WezTerm color scheme](https://wezfurlong.org/wezterm/colorschemes/index.html) and remove the manual `colors` block.
