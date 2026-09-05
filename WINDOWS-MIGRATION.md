# Moving the Windows machine to WSL2

You're on Windows 11 with WSL2 and WSLg already working, and Emacs already runs in WSL2. What's
left is the rest of it: the dotfiles themselves, `~/coding`, and Claude Code all still live on the
Windows side. This moves them across so the Windows box runs the same unix setup as everything
else, with WezTerm as the native GUI on top.

Budget an hour, most of which is waiting on cargo. Do it in one sitting, because you'll have
projects in two places until step 5 finishes.

> **Read step 5 before you start.** It's the one that touches your actual work, and it wants your
> repos pushed first.

## Why bother

These dotfiles are about 90% unix. The native Windows path skips zsh, starship, eza, zoxide, and
Emacs entirely, and it can't run `build-emacs.sh` at all. WSL2 gets you all of it, plus cargo
builds that don't need MSVC, plus a real C compiler so nvim-treesitter stops failing on parser
installs. The installer gets simpler too: the Windows side drops from 11 winget packages to 2.

## What ends up where

| Thing | Lives on | Why |
|-------|----------|-----|
| WezTerm | **Windows** | It's the GUI. Native app, talks to a WSL pty |
| JetBrainsMono Nerd Font | **Windows** | WezTerm renders it, so Windows needs it |
| `~/.config` (this repo) | **WSL2** | Everything in it is unix |
| `~/coding` | **WSL2** | Crossing the 9p boundary is 10-20x slower |
| Node, npm, Claude Code | **WSL2** | See step 6. Windows Node breaks the code-style hook |
| Nothing else | Windows | Seriously. Don't install Node on the host |
| Emacs | **WSL2** | Already is. WSLg gives it a real GUI frame |

Nothing you care about stays on `C:` except WezTerm and the font.

---

## 1. Confirm WSL2 and pick your distro

```powershell
wsl --list --verbose
```

You want a distro with **VERSION 2**. If one says `1`:

```powershell
wsl --set-version <distro> 2
```

No distro at all:

```powershell
wsl --install -d Ubuntu
```

The rest of this doc assumes Ubuntu. Any Debian-based distro works identically; Fedora and Arch
work too, the installer detects all three.

## 2. Install the Windows host side

From the repo on the Windows side (or after cloning it there temporarily):

```powershell
pwsh install.ps1 -DryRun    # read the plan first
pwsh install.ps1
```

That's WezTerm plus the Nerd Font, and a WSL2 check. Two winget packages.

**`install.ps1` needs nothing but winget.** No Node, no dependencies. That's deliberate: step 6 is
about keeping Windows Node out of your WSL PATH, and it would be silly for the installer to make
you install the exact thing it warns about. It's the one script in this repo that isn't a shim
around the TypeScript installer, and the two winget ids it carries are asserted against the
registry by the test suite so they can't drift.

It deliberately does **not** install the dotfiles, and it'll tell you so at the end.

## 3. Install Node inside WSL

Do this before cloning, because the installer needs it. **Inside WSL, not on Windows.**

```sh
# Inside WSL: wsl -- bash, or just open the distro
sudo apt update && sudo apt install -y curl git
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
exec $SHELL
nvm install --lts
```

Verify you got the Linux one, not the Windows one leaking through PATH interop:

```sh
command -v node          # want /home/<you>/.nvm/...  NOT /mnt/c/...
node -e 'console.log(process.platform, require("os").homedir())'
# want: linux /home/<you>
```

If that prints `win32` and a `C:\` path, stop and fix it now. Step 6 explains why it matters.

## 4. Clone and install the dotfiles

```sh
git clone git@github.com:austin-meier/dotfiles.git ~/.config
cd ~/.config
bash install.sh --dry-run     # read the plan
bash install.sh
exec zsh
```

This is the normal Debian path, same as any Linux box. It installs zsh, the cargo tools, Neovim
from the official tarball, clangd, cmake, the zsh plugins, sets `ZDOTDIR`, `chsh`es you to zsh,
and links the Claude config into `~/.claude`.

It also runs a **WSL2 health** step that checks the things in step 6 for you.

## 5. Move `~/coding` across

**This is the step that touches real work. Do the check first.**

Re-clone rather than copy. A copy across `/mnt/c` drags Windows line endings and file modes with
it, and it's slow. The only thing a copy gets you that a clone doesn't is uncommitted work, so
find that first.

### 5a. Find anything unpushed or uncommitted

From inside WSL, pointed at the Windows-side folder:

```sh
WINDOWS_CODING="/mnt/c/Users/<YOUR_USER>/coding"

for repo in "$WINDOWS_CODING"/*/*/.git; do
  dir="$(dirname "$repo")"
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null)"
  unpushed="$(git -C "$dir" log --branches --not --remotes --oneline 2>/dev/null)"
  stashes="$(git -C "$dir" stash list 2>/dev/null)"

  if [ -n "$dirty" ] || [ -n "$unpushed" ] || [ -n "$stashes" ]; then
    echo "=== $dir"
    [ -n "$dirty" ]    && echo "  uncommitted: $(echo "$dirty" | wc -l) file(s)"
    [ -n "$unpushed" ] && echo "  unpushed:    $(echo "$unpushed" | wc -l) commit(s)"
    [ -n "$stashes" ]  && echo "  stashes:     $(echo "$stashes" | wc -l)"
  fi
done
```

**A clean result prints nothing.** Anything it does print, go commit and push before continuing.
Don't skip the stash line, stashes are the classic thing people lose in a migration.

### 5b. Re-clone into WSL

```sh
mkdir -p ~/coding/{js,rust,python,clojure,c}   # whatever languages you actually use

# then per project
git clone git@github.com:<org>/<repo>.git ~/coding/js/<repo>
```

To list what you had, so you don't miss one:

```sh
ls -d "$WINDOWS_CODING"/*/*/ | sed "s|$WINDOWS_CODING/||"
```

### 5c. Carry over anything untracked but wanted

Per project, `.env` files and local configs are usually the only things git didn't take:

```sh
cp "$WINDOWS_CODING/js/<repo>/.env" ~/coding/js/<repo>/.env
```

### 5d. Leave the Windows copy alone for a week

Don't delete `C:\Users\<you>\coding` today. Rename it to `coding.old` and revisit once you're sure
nothing's missing. Disk is cheap, a lost stash isn't.

## 6. Make sure Claude Code is the Linux one

This is the cause of most "Claude Code acts weird in WSL" reports, and it's worth understanding
rather than just fixing.

The code-style hook in `claude/settings.json` resolves its own path this way:

```
node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"
```

If `node` resolves to the **Windows** `node.exe` through PATH interop, `os.homedir()` returns
`C:\Users\<you>`, the require path doesn't exist, and the `PreToolUse` hook throws on **every**
Write/Edit/MultiEdit. It looks like Claude being flaky. It isn't.

Check:

```sh
command -v node claude npm
node -e "console.log(require('fs').existsSync(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs'))"
# want: true
```

Install Claude Code inside WSL, then verify the whole config:

```sh
claude   # then, inside Claude:
/verify-settings
```

Optionally stop Windows paths leaking into WSL's PATH entirely:

```sh
sudo tee -a /etc/wsl.conf >/dev/null <<'CONF'
[interop]
appendWindowsPath = false
CONF
```

Then `wsl --shutdown` from PowerShell and reopen. **The tradeoff:** you lose calling Windows exes
by name from inside WSL (`code .`, `explorer.exe .`). Worth it if PATH interop keeps biting you,
skip it otherwise.

## 7. Point WezTerm at WSL

Already done if you pulled this repo. `wezterm/wezterm.lua` now does:

```lua
config.wsl_domains = wezterm.default_wsl_domains()
config.default_domain = 'WSL:Ubuntu'   -- or the first distro it finds
```

WezTerm's config stays on the **Windows** side (`C:\Users\<you>\.wezterm.lua` or
`%USERPROFILE%\.config\wezterm\`), because WezTerm is a Windows app. Point it at the repo copy in
WSL, or symlink it. Every keybind, the doom-one palette, and the Shift+Enter fix for Claude Code
work unchanged.

Falls back to Nushell or pwsh if no distro is installed, so it won't break on a fresh box.

## 8. Browser handoff for OAuth

Claude Code's `/login` and any `xdg-open` need a way out to Windows:

```sh
sudo apt install -y wslu
wslview https://example.com   # should open your Windows browser
```

The installer's WSL2 health step warns if this is missing.

## 9. Final check

```sh
cd ~/.config
bash install.sh --dry-run    # everything should say "already installed"
exec zsh
```

Then:

| Check | Expect |
|-------|--------|
| `echo $SHELL` | `/usr/bin/zsh` or similar |
| Prompt | starship, doom-one colors, git status |
| `ls` | eza with icons |
| `nvim` | opens in ~20ms, `:Lazy profile` shows 2 startup plugins |
| Open a `.clj` in nvim | rainbow parens, no treesitter errors |
| `emacs` | WSLg frame, `SPC` tree works |
| `readlink -f ~/coding` | a `/home/...` path, **not** `/mnt/c` |
| `/verify-settings` in Claude | all green |

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Everything is slow, `git status` takes seconds | Files on `/mnt/c` | Move them into the WSL filesystem. Step 5 |
| Claude Code errors on every file edit | Windows `node.exe` in PATH | Step 6 |
| nvim file watching misses changes | inotify doesn't work over 9p | Same, files must be in ext4 |
| `wsl --install` says it needs a reboot | It does | Reboot, then re-run `pwsh install.ps1` |
| Treesitter parser installs fail | No C compiler | `sudo apt install build-essential` |
| Emacs opens in the terminal, paredit keys dead | No WSLg frame | Check `echo $DISPLAY` is set. `config.org:887` explains why those bindings need a GUI |
| `/login` never opens a browser | No `wslview` | Step 8 |
| WezTerm opens PowerShell, not WSL | No distro when WezTerm started | `wsl -l -v`, then `C-S-r` in WezTerm to reload |

## Maintenance note

Once `coding.old` is deleted and this has stuck, this doc is done. Leave it in the repo anyway,
it's the runbook for the next Windows machine.
