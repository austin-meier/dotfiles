# Emacs

[← Back to the index](../CLAUDE.md)

A from-scratch config, not DOOM, but shamelessly DOOM-flavored: evil mode, `SPC` leader, doom-one
theme, doom-modeline. I wanted the DOOM ergonomics without the DOOM framework sitting between me
and my own config.

Everything meaningful lives in `emacs/config.org`, a literate config that `init.el` loads with
`org-babel-load-file`. Edit the org file, not the tangled output.

## Files

| File | Job |
|------|-----|
| `config.org` | The actual config. ~1700 lines, org-babel blocks, has its own TOC |
| `init.el` | Four lines that load `config.org`, plus whatever `custom-set-variables` scribbles in |
| `early-init.el` | Runs before the first frame. Frame settings and the macOS native-comp fix |
| `build-emacs.sh` | Portable source build of Emacs itself |
| `.gitignore` | Nested whitelist, since an Emacs dir generates a mountain of state |

## early-init.el, and the macOS native-comp mess

Frame settings (maximized, no toolbar, no menu bar, no scroll bars) get pushed into
`default-frame-alist` here so there's no visible flash of the wrong size on launch.

The other half is a macOS workaround that took an annoying amount of time to pin down. libgccjit
shells out to the gcc driver to link each `.eln` file, and that link fails with
`error invoking gcc driver` unless `LIBRARY_PATH` points at both the Homebrew gcc runtime and the
SDK's libSystem. GUI launches don't inherit your shell environment, so it has to be set here,
before anything can trigger native compilation.

The paths use Homebrew's `current` symlinks so a gcc version bump doesn't break it, and it globs
for the version-specific target subdir (`.../current/gcc/aarch64-apple-darwin25/15`) because
`libemutls_w.a` lives in there and the trampoline link needs it.

## Package management

[Elpaca](https://github.com/progfolio/elpaca), with `package-enable-at-startup` disabled in
`early-init.el` so the built-in `package.el` stays out of the way.
[no-littering](https://github.com/emacscollective/no-littering) keeps generated state out of the
config directory, which is what makes the whitelist gitignore practical.

## The SPC tree

`general.el` defines one `austin/leader-key` definer with `SPC` as the prefix and `M-SPC` as the
global prefix so the leader still works in insert state. One central block, mirrored almost
key-for-key by the [Neovim config](nvim.md).

| Prefix | Group |
|--------|-------|
| `SPC a` | AI (claude-code-ide) |
| `SPC b` | Buffers |
| `SPC f` | Files |
| `SPC o` | Open |
| `SPC p` | Projects |
| `SPC g` | Git (magit) |
| `SPC t` | Tabs |
| `SPC w` | Windows |
| `SPC h` | Help |
| `SPC c` | Code / LSP |
| `SPC e` | Eval or build, mode-local |
| `SPC :` | `M-x` |
| `SPC ;` | `embark-act` |

`SPC c` splits the same way Neovim does: `ca` actions, `cg` goto, `cp` peek (lsp-ui, Emacs only),
`ce` errors, `cw` workspace, `cu` UI, `ct` treemacs trees, `cd` dap.

`SPC w m h/j/k/l` moves the *current window* in a direction, using the same h/j/k/l verbs as the
`C-h/j/k/l` focus movement. Focus with control, move with the leader.

`SPC e` is mode-local and means different things per language: eval in elisp and Clojure, build
and run in Rust, C/C++, and Ada.

## Completion stack

Vertico, orderless, consult, marginalia, embark, plus prescient for sorting. Company handles
in-buffer completion.

## LSP

`lsp-mode`, and every language hook is gated on `executable-find`:

```elisp
(defun austin/lsp-ts ()
  (when (executable-find "typescript-language-server") (lsp)))
```

Missing server means the hook is a silent no-op instead of an error banner every time you open a
file. Wired up for TypeScript/JavaScript, Rust, JSON, and C/C++ (clangd).

Format-on-save is on by default for LSP buffers via `austin/format-on-save`, toggled at runtime
with `SPC c a F`.

## Languages

| Language | Setup |
|----------|-------|
| Emacs Lisp | `SPC e` for eval buffer / region / last sexp / defun |
| Clojure | CIDER, with lispyville and paredit for structural editing |
| Racket | `racket-xp-mode`, a background analyzer giving jump-to-def, hover docs, and completion with no external LSP server. Just needs `racket` on PATH |
| Ada | LSP, navigation, format-on-save. Build helpers detect the project shape: `alire.toml` builds with alr, loose sources with gnatmake. No test runner binding and no dap adapter, so debugging stays on the command line |
| C/C++ | clangd plus the tree-sitter modes. `SPC e` builds, `SPC c d` debugs via dap |

clangd needs a `compile_commands.json` to resolve includes. CMake emits one with
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, which the `SPC e b` build helper passes automatically. For
Makefile projects use [bear](https://github.com/rizsotto/Bear).

## Notable plugins

magit, treemacs, which-key, eat (terminal), yasnippet, aggressive-indent, rainbow-delimiters,
helpful, avy, ace-window, GCMH for garbage collection, org-modern and org-fragtog for org, and
[claude-code-ide.el](https://github.com/manzaltu/claude-code-ide.el) under `SPC a`.

## Building Emacs from source

`build-emacs.sh` downloads, configures, compiles, and installs Emacs with native-compilation,
tree-sitter, JSON, dynamic modules, and the full image stack.

```sh
bash emacs/build-emacs.sh [--version 30.2] [--src DIR] [--native aot|yes|no] [--gui ns|pgtk|x11] [--yes]
```

| Platform | Result |
|----------|--------|
| macOS | Cocoa (NS) toolkit, produces `Emacs.app` in `/Applications` |
| Fedora | pgtk (Wayland), installs to `/usr/local` |
| Debian/Ubuntu/Arch | X11/GTK3, installs to `/usr/local` |

Defaults are Emacs 30.2, sources in `~/src`, AOT native compilation. Budget 20 to 40 minutes,
because AOT recompiles all the bundled elisp. Use `--native yes` for lazy compilation if you'd
rather not wait.

Env overrides work too: `EMACS_VER`, `SRC_ROOT`, `NATIVE_COMP`, `EMACS_GUI`.
