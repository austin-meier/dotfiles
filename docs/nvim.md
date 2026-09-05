# Neovim

[← Back to the index](../CLAUDE.md)

Started from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and then got dragged
toward my [Emacs config](emacs.md) until the two felt like the same editor. The whole `SPC` tree
is deliberately a mirror of the Emacs one, so `SPC g s` opens git status in both and `SPC c g d`
jumps to definition in both.

Requires Neovim >= 0.10.

## Startup budget

nvim is the snappy editor, Emacs is the kitchen sink. Concretely that means:

- `vim.loader.enable()` is the first line of `init.lua`. It byte-compiles and caches every Lua
  module, and it's the single biggest win on Windows where an uncached `require` is a fresh stat
  plus read that Defender also wants to scan.
- **Every spec carries an `event` / `ft` / `cmd` / `keys` trigger.** Only doom-one and lazy.nvim
  load before the first frame. Note that `event = "VimEnter"` is not lazy loading, it's "load at
  startup, slightly later", which is what kickstart ships and what got ripped out here.
- lazy's `change_detection` and `rocks` are off (libuv watchers and luarocks probing at startup),
  and the dead built-in rtp plugins (netrw, tar, zip, gzip, tutor, rplugin, spellfile, tohtml) are
  disabled. matchit and matchparen are deliberately left on.
- The python/perl/ruby/node providers are disabled in `vim-options.lua`. Nothing here uses remote
  plugins, and leaving them on makes Neovim probe PATH for four interpreters at startup.
- mason-tool-installer runs with `start_delay = 3000`. Loading the mason registry is the slowest
  step in the LSP chain and nothing needs it to have finished.

Check the damage with `:Lazy profile`, or measure it:

```sh
nvim --headless --startuptime /tmp/st.log -c 'qa' && tail -1 /tmp/st.log
```

For reference, on an M-series Mac: ~18ms for bare `nvim`, ~80ms when opening a source file (which
is when treesitter, LSP, gitsigns, and rainbow-delimiters all wake up).

## Layout

```
nvim/
  init.lua                       bootstraps lazy.nvim, loads the three austin/ modules
  lua/austin/
    vim-options.lua              raw vim options
    keybinds.lua                 the entire SPC tree, one file
    autocommands.lua             currently just yank highlighting
    plugins/*.lua                one file per plugin, auto-imported by lazy
```

`keybinds.lua` being one central file is on purpose. It mirrors the single `austin/leader-key`
block in the Emacs config. Bindings use lazy `require(...)` callbacks so they still work with
lazy-loaded plugins, and the group labels live in `plugins/which-key.lua`.

Plugins are pinned by `lazy-lock.json`. Update checking is off, run `:Lazy update` when you
actually want to.

## The SPC tree

Leader is `SPC` for both `mapleader` and `maplocalleader`. `SPC SPC` switches buffer.

| Prefix | Group |
|--------|-------|
| `SPC a` | AI (Claude Code in a terminal split) |
| `SPC b` | Buffers |
| `SPC f` | Files |
| `SPC o` | Open (tree, terminal, config) |
| `SPC p` | Projects |
| `SPC g` | Git |
| `SPC t` | Tabs |
| `SPC w` | Windows |
| `SPC h` | Help |
| `SPC c` | Code / LSP |
| `SPC e` | Eval / build (mode-local) |
| `SPC :` | Command palette (Emacs `M-x`) |
| `SPC ;` | Act on thing at point (Emacs `embark-act`) |
| `SPC x` | Eval a Lua expression |

Non-leader movement matches the editors and the terminal: `C-h/j/k/l` for window focus,
`C-←` / `C-→` and `C-S-h` / `C-S-l` for tabs.

### SPC e, build and eval

Buffer-local, set from `FileType` autocmds in `autocommands.lua`, the same way general.el scopes
its `SPC e` blocks with `:keymaps '<mode>-map`. The helpers live in `austin/build.lua` and open a
terminal split with a window-local `lcd` into the project root, so there's no shell-specific
`cd &&` chaining to break on Windows.

| Filetype | Bindings |
|----------|----------|
| `rust` | `eb` cargo build, `er` cargo run, `et` cargo test |
| `c` / `cpp` | `eb` cmake-or-make-or-file, `er` compile + run, `ef` compile file, `et` ctest/make test |
| `ts` / `js` | `er` dev server, `ed` dev server, `ef` run file with node, `es` pick an npm script |
| `lua` | `eb` source buffer, `ee` eval line, `er` eval selection |
| everywhere | `eR` repeat last, `ec` prompt for a command |

Clojure is deliberately absent from that table. Conjure owns `<localleader>e` and localleader is
`SPC` here, so its eval tree already lands on `SPC e` for free.

### SPC c, the code tree

This is the big one, and it's split by verb:

| Keys | Group |
|------|-------|
| `SPC c a` | Actions: code action, rename, signature, organize imports |
| `SPC c g` | Goto: definition, declaration, implementation, type def, references, symbols |
| `SPC c u` | UI: hover doc |
| `SPC c e` | Errors: next, previous, list |
| `SPC c w` | Workspace: restart LSP, add/remove folder |
| `SPC c d` | Debug (nvim-dap): continue, step over/into/out, breakpoints, toggle UI |

`SPC c a f` (format) is intentionally missing from `keybinds.lua`, conform owns it in
`plugins/format.lua`.

`SPC c a F` toggles format-on-save by flipping `vim.g.disable_autoformat`, which conform's
`format_on_save` hook reads (Emacs `austin/toggle-format-on-save`).

Diagnostic jumping goes through a small `diag_jump` wrapper because 0.11 replaced
`vim.diagnostic.goto_next` with `vim.diagnostic.jump`. The wrapper checks for the new API and
falls back, so the config works on both.

### SPC g, git

Neogit for porcelain (`gs` status, `gc` commit, `gp` push, `gP` pull, `gf` fetch, `gl` log,
`gb` branch, `gm` merge, `gr` rebase, `gt` tag, `gD` diff popup), gitsigns for hunks (`gh s` stage,
`gh r` reset, `gh p` preview, `]h` / `[h` to navigate). Same split as Emacs, where magit does
porcelain and the gutter does hunks.

`gC` (clone) shells out rather than opening a popup, because Neogit doesn't have a clone popup.

### SPC p, projects

There's no project.nvim. `austin/project.lua` scans `~/coding/{language}/{project}` directly, which
is the layout every machine uses anyway. `po` picks a project, `tcd`s into it, and opens the file
picker; `pk` kills every buffer under the current root.

## Parity with Emacs, and where it breaks

The `SPC` trees line up almost everywhere. The gaps that can't close, and why:

| Emacs | Status here |
|-------|-------------|
| `SPC a p` / `a @` / `a s` / `a m` | claude-code-ide.el IDE integrations. `SPC a` here is a terminal running the CLI, so send-prompt, insert-`@file`, session list, and the transient menu have nothing to bind to |
| `SPC t d` detach tab, `SPC t r` rename tab | Neovim tabs are window layouts, not frames. No detach, no names |
| `SPC c s` insert snippet | LuaSnip is installed but friendly-snippets is commented out, so there's nothing to insert yet |
| `SPC e` for Ada and Racket | No Ada or Racket support in this config at all |
| `SPC e r j` cider-jack-in | Conjure connects to a running nREPL, it doesn't start one |
| `C-=` / `C--` / `C-0` font size | Terminal-level concern. Bound in [WezTerm](wezterm.md) instead |

A few bindings are approximations rather than exact matches: `SPC ;` maps embark-act onto
`code_action`, `SPC c p` (peek) reuses the telescope pickers since they already preview, and
`SPC c t` (lsp-treemacs trees) reuses telescope for the same reason.

## Plugins

| Plugin | Job |
|--------|-----|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Package manager |
| [doom-one.nvim](https://github.com/NTBBloodbath/doom-one.nvim) | Theme, matches everything else |
| [telescope](https://github.com/nvim-telescope/telescope.nvim) + fzf-native | Every picker in the SPC tree |
| [blink.cmp](https://github.com/saghen/blink.cmp) + LuaSnip | Completion |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) + mason | LSP |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatting |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax and indent |
| [neogit](https://github.com/NeogitOrg/neogit) | Magit-alike |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Gutter signs and hunk ops |
| [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) | File tree |
| [which-key](https://github.com/folke/which-key.nvim) | The popup that makes the SPC tree usable |
| [flash.nvim](https://github.com/folke/flash.nvim) | Jump-to-anywhere, the avy equivalent |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) + dap-ui | Debugging |
| [austin/build.lua](../nvim/lua/austin/build.lua) | Not a plugin. `SPC e` build/run/eval helpers |
| [austin/project.lua](../nvim/lua/austin/project.lua) | Not a plugin. `SPC p` project switching |
| [austin/ai.lua](../nvim/lua/austin/ai.lua) | Not a plugin. `SPC a` Claude Code terminal |
| [conjure](https://github.com/Olical/conjure) | Clojure REPL |
| [nvim-paredit](https://github.com/julienvincent/nvim-paredit) | Structural lisp editing |
| [rainbow-delimiters](https://github.com/HiPhish/rainbow-delimiters.nvim) | Paren colors |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close delimiters |
| [lualine](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [guess-indent](https://github.com/NMAC427/guess-indent.nvim) | Detect indent from the file |
| [vim-surround](https://github.com/tpope/vim-surround) + vim-repeat | tpope tax |
| [lazydev](https://github.com/folke/lazydev.nvim) | Lua LSP that knows about the nvim API |

## Tree-sitter parsers need a compiler

Parsers are compiled on the machine, so `ensure_installed` and `auto_install` are both gated on
finding `cc`, `gcc`, `clang`, `cl`, or `zig` on PATH. Without one, every install attempt fails
loudly on every file you open, and rainbow-delimiters goes down with it because it attaches to the
parser.

Native-Windows boxes land here. The fix is a compiler: on WSL2 that's `build-essential`, which the
installer already pulls in, so running Neovim inside WSL2 makes this a non-issue. On a genuinely
native Windows setup, install [zig](https://ziglang.org) (`winget install zig.zig`) or the MSVC
build tools, then run `:TSUpdate`. If the gate trips you get a one-time warning saying exactly
that.

rainbow-delimiters has a matching guard: its `condition` checks for a working parser before
attaching, and skips files over 10k lines because the global strategy re-runs on every edit.

## LSP servers

mason-tool-installer installs `lua_ls` (the only one with real settings, configured for the
nvim API), plus `clojure-lsp`, `jdtls`, `typescript-language-server`, and `stylua`.

Everything else in the `servers` table is commented out. Uncomment what you need, mason will pick
it up on next launch.

## Options worth knowing

Relative numbers on, `expandtab` with 2-space indent (guess-indent overrides per file), undofile
on, `smartcase` search, `inccommand = "split"` for live substitution preview, `scrolloff = 10`,
`confirm = true` so `:q` with unsaved changes asks instead of erroring. Clipboard is
`unnamedplus`, set inside `vim.schedule` because touching it during startup is slow.
