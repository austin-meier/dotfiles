# Moving the Windows machine to WSL2

You're on Windows 11 with WSL2 and WSLg already working, and a lot more than that. When I actually
audited this box (September 2026) the Ubuntu-24.04 distro already had zsh, the cargo tools, Neovim,
a source-built Emacs, Linux Node, and a stale clone of these dotfiles sitting in it. What's still on
the Windows side is `~/coding`, Claude Code, Node, and the copy of this repo that WezTerm and
`~/.claude` currently point at. This moves the rest across so the Windows box runs the same unix
setup as everything else, with WezTerm as the native GUI on top.

Budget an hour if the box is fresh. On this box the install steps are mostly "confirm it's done",
and the time goes into step 5, which is the one that touches real work. Do step 5 in one sitting,
because you'll have projects in two places until it finishes.

> **Read steps 0 and 5 before you start.** Step 0 is a repo cleanup that has to land on origin
> before WSL pulls. Step 5 has a section for repos that can't be cloned, and this box has 23 of
> those.

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

## Where this box is right now

Snapshot from the audit, so you know which steps are real and which are a checkbox. If you're
reading this on the *next* Windows machine, skip this section and run every step in full.

| Area | State |
|------|-------|
| WSL | 2.4.11, WSLg 1.0.65, one distro (`Ubuntu-24.04`, version 2, default), systemd on |
| WezTerm | Installed via winget. Loads its config from `C:\Users\austi\.config\wezterm\wezterm.lua`, which is this repo |
| Nerd Font | **Missing.** Only Adwaita Mono and Hasklug Nerd Fonts are on the box. `install.ps1` fixes it |
| `pwsh` | **Not installed.** `install.ps1` runs fine under Windows PowerShell 5.1, so use `powershell -File` |
| WSL user | `austin`, zsh is the login shell, `ZDOTDIR` set, keychain loads `id_wsl` |
| GitHub key in WSL | `id_wsl` is registered as `desktop-wsl` and authenticates. Nothing to copy from Windows |
| Node in WSL | 24.16 from NodeSource, Linux build, homedir is `/home/austin`. The step 6 hook check already passes |
| Dotfiles in WSL | Cloned at `~/.config` but **17 commits behind** and predates the TypeScript installer, `docs/`, and this doc |
| Uncommitted in WSL | `emacs/config.org` has a project-create command on `SPC p c` and a company-mode fix for eshell. **Only exists in WSL.** Step 4 saves it |
| Already installed in WSL | starship, eza, zoxide, rg, fd (cargo), fzf, build-essential, gcc, Neovim, Emacs 30.2 (source build), Clojure CLI, OpenJDK 25 |
| Missing in WSL | Claude Code, wslview, clangd, cmake, gh, maven, Go, docker |
| `~/.claude` in WSL | Just an `ide/` folder. No symlinks, no MCP servers |
| `~/coding` in WSL | Already has a few clojure, js, rust, and racket projects. Two of them have unpushed commits and no remote (`bunzervisor`, `bunz-dashboard`) |
| PATH interop | 51 Windows entries appended. Bare `node` is Linux, but `node.exe`, `python.exe`, and `java.exe` reach Windows binaries |
| This repo on Windows | `claude/settings.json` unmerged in the index from a finished rebase, plus a leftover autostash. Step 0 |
| `~/coding` on Windows | 76 git repos, 5.1 GB without build junk, 23 repos with no remote, 6 with unpushed commits, 4 with stashes |

---

## 0. Clean up the repo on the Windows side

WSL pulls from origin, so anything that only exists in the Windows working tree has to get there
first. Right now `git status` shows `claude/settings.json` as unmerged. The working copy is the
correct resolution (it's HEAD plus the shopify-ai-toolkit plugin and the push notification flag).
The autostash holds the same two lines on an older base with a stale model id, so it's safe to
drop once the commit exists.

```sh
cd ~/.config
git add claude/settings.json
git commit -m "enable shopify toolkit plugin and agent push notifications"
git stash drop
rm .git/REBASE_HEAD
git push
```

`REBASE_HEAD` is a leftover marker, not an in-progress rebase. Git already reports the branch as
up to date with origin, this just tidies the file.

## 1. Confirm WSL2 and pick your distro

Done on this box. For the record:

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

`pwsh` isn't on this box and the script doesn't need it. Windows PowerShell 5.1 runs it fine:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -DryRun    # read the plan first
powershell -ExecutionPolicy Bypass -File install.ps1
```

That's WezTerm plus the Nerd Font, gated on WSL2. Two winget packages. WezTerm is already
installed here, so the only real change is the font.

**WSL2 is required now, not just checked.** These dotfiles are unix; the host is only the terminal
and its font, so there's nothing worth installing if WSL2 isn't there. No WSL2 distro and the
script stops and points you at `wsl --install`. If a box genuinely can't run WSL2, `-Native` is the
escape hatch (you lose zsh, starship, and Emacs, and that path does need Node on Windows).

**It also sets `WEZTERM_CONFIG_FILE`** to the WSL copy of `wezterm.lua`, but only once that clone
exists (step 4). On a fresh box the clone isn't there yet when you run this, so it skips with a
note. Re-run `install.ps1` after step 4 and it sets the var for you. On this box the clone was
already in place, so it's set. See step 7.

**`install.ps1` needs nothing but winget.** No Node, no dependencies. That's deliberate: step 6 is
about keeping Windows Node out of your WSL PATH, and it would be silly for the installer to make
you install the exact thing it warns about. It's the one script in this repo that isn't a shim
around the TypeScript installer, and the two winget ids it carries are asserted against the
registry by the test suite so they can't drift.

It deliberately does **not** install the dotfiles, and it'll tell you so at the end.

## 3. Install Node inside WSL

Done on this box. NodeSource already put a Linux Node 24 in `/usr/bin`, which clears the installer's
22.18 floor, so skip nvm entirely. Just confirm it's the Linux one:

```sh
command -v node          # want /usr/bin/node or /home/<you>/.nvm/...  NOT /mnt/c/...
node -e 'console.log(process.platform, require("os").homedir())'
# want: linux /home/<you>
```

If that prints `win32` and a `C:\` path, stop and fix it now. Step 6 explains why it matters.

On a fresh box with no Node, do this before cloning, because the installer needs it. **Inside
WSL, not on Windows.**

```sh
sudo apt update && sudo apt install -y curl git
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
exec $SHELL
nvm install --lts
```

## 4. Pull the dotfiles (don't re-clone)

The clone at `~/.config` in WSL is real, it's just old. It also has the only copy of some Emacs
work, so save that first. The tracked `git/config` sets pull to rebase with autostash, so the order
below is safe even if you forget the commit.

```sh
cd ~/.config
git add emacs/config.org
git commit -m "emacs: project-create command, keep company out of eshell"
git pull
git push
bash install.sh --dry-run     # read the plan
bash install.sh
exec zsh
```

What to expect from the installer on this box:

- clangd and cmake get installed via apt. Everything else says "already installed".
- It backs up and removes the WSL `~/.gitconfig`. Its contents match the tracked `git/config`, so
  nothing is lost.
- It links `settings.json`, `CLAUDE.md`, `skills/`, `commands/`, `agents/`, `output-styles/`, and
  `libs/` from `~/.claude` into the repo.
- The **MCP servers** step skips itself because there's no `claude` binary yet. That's fine.
  Re-running `bash install.sh` after step 6 registers them.
- The **WSL2 health** step warns that wslview is missing. Step 8 fixes it, and you want it before
  step 6 because Claude's login needs a browser.

On a fresh box it's the normal Debian path, same as any Linux box:

```sh
git clone git@github.com:austin-meier/dotfiles.git ~/.config
cd ~/.config
bash install.sh
exec zsh
```

## 5. Move `~/coding` across

**This is the step that touches real work. Do the checks first.**

Re-clone rather than copy. A copy across `/mnt/c` drags Windows line endings and file modes with
it, and it's slow. Windows git on this box has `core.autocrlf=true`, so every checkout over there is
CRLF. A fresh clone into ext4 is LF from the start, which is the whole point.

The catch the old version of this doc missed: cloning only works for repos that have a remote.
This box has 23 that don't, and 22 of those have zero commits (learning projects that got a
`git init` and nothing else). Those can't be cloned or bundled. They get copied or left behind.
Section 5d covers them.

### 5a. Find anything unpushed, uncommitted, stashed, or remote-less

Run this from **Git Bash on the Windows side**, not from WSL. Running it from WSL over 9p makes
git see every CRLF file as modified and the dirty counts balloon (AoC went from 4 files to 29).
Same loop, wrong lens.

The layout isn't strictly `{language}/{project}`. AoC, Brookebot, PowerOps, CMake_OpenGLBasics, and
mit sit at the top level, so the loop checks both depths.

```sh
W="$HOME/coding"

for repo in "$W"/*/.git "$W"/*/*/.git; do
  [ -e "$repo" ] || continue
  dir="$(dirname "$repo")"
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null)"
  unpushed="$(git -C "$dir" log --branches --not --remotes --oneline 2>/dev/null)"
  stashes="$(git -C "$dir" stash list 2>/dev/null)"
  remote="$(git -C "$dir" remote get-url origin 2>/dev/null)"

  if [ -n "$dirty" ] || [ -n "$unpushed" ] || [ -n "$stashes" ] || [ -z "$remote" ]; then
    echo "=== ${dir#$W/}  ${remote:-NO REMOTE}"
    [ -n "$dirty" ]    && echo "  uncommitted: $(echo "$dirty" | wc -l) file(s)"
    [ -n "$unpushed" ] && echo "  unpushed:    $(echo "$unpushed" | wc -l) commit(s)"
    [ -n "$stashes" ]  && echo "  stashes:     $(echo "$stashes" | wc -l)"
  fi
done
```

**A clean result prints nothing.** It won't be clean here. What the audit found, so you can
check them off:

| Repo | Unpushed | Stashes | Dirty | Note |
|------|----------|---------|-------|------|
| `clojure/pdf` | 19 | 2 | | Push it. Deal with the stashes |
| `php/jam` | 15 | | yes | Push it |
| `js/admin-ui` | 8 | | | Push it |
| `js/reactecom` | 1 | 2 | yes | Push it. Deal with the stashes |
| `js/olympus` | 1 | | | Push it |
| `js/designer` | 1 | | 13 files | **No remote.** Make one and push, or copy |
| `js/netsuite-kit` | | 1 | | Apply and commit, or accept losing it |
| `rust/alchemy` | | 1 | 23 files | Same |
| `js/tiktok` | | | 38 files | Look before you decide |
| `python/chilitools` | | | 31 files | Same |
| `c/idle-c` | | | 14 files | Same |
| `pheonix/hello` | | | 11 files | No remote, no commits. Copy or drop |

Most of the small dirty counts are untracked `.lsp/`, `.clj-kondo/`, and Calva output dirs. Not
work, just tool litter. The stashes are the thing to be careful with. Either `git stash pop` and
commit to a WIP branch, or make peace with them staying in `coding.old`.

Also note the checked-out branches. `clojure/clojure-camp` is on `feature/sponsorship-page`,
`go/ProLUG-Events` is on `feature/discord-bot`, and the JAM Java services are on `develop` or a
feature branch. You'll want the same branch after cloning.

### 5b. Re-clone into WSL

Print a clone list, with branch, from the Windows side. Save it somewhere WSL can see.

```sh
W="$HOME/coding"
for repo in "$W"/*/.git "$W"/*/*/.git; do
  [ -e "$repo" ] || continue
  dir="$(dirname "$repo")"
  remote="$(git -C "$dir" remote get-url origin 2>/dev/null)" || continue
  echo "${dir#$W/} $remote $(git -C "$dir" branch --show-current)"
done > "$W/clone-list.txt"
```

Then inside WSL:

```sh
mkdir -p ~/coding/{js,rust,python,clojure,c,java,go,php,schema}

while read -r path remote branch; do
  [ -e ~/coding/"$path" ] && { echo "skip $path (exists)"; continue; }
  git clone --branch "${branch:-main}" "$remote" ~/coding/"$path"
done < /mnt/c/Users/austi/coding/clone-list.txt
```

The `exists` check matters on this box. WSL's `~/coding` already has projects in it, including two
with unpushed commits and no remote (`clojure/bunzervisor`, `js/bunz-dashboard`, and there are
`.bundle` files for both sitting in the WSL home). Don't clobber them.

A handful of remotes are `https://` clones of other people's repos (Brookebot, CMake_OpenGLBasics,
idle-c, assimp and friends). Those clone fine without a key.

### 5c. Carry over `.env` files and local Claude settings

Per project, `.env` files and `.claude/settings.local.json` are the things git didn't take. The
audit found 31 `.env` variants and 25 local settings files. This copies both into every project
that now exists in WSL, and never overwrites:

```sh
W=/mnt/c/Users/austi/coding
for src in "$W"/*/.env* "$W"/*/*/.env* "$W"/*/.claude/settings.local.json "$W"/*/*/.claude/settings.local.json; do
  [ -e "$src" ] || continue
  rel="${src#$W/}"
  dst="$HOME/coding/$rel"
  proj="${rel%%/.env*}"; proj="${proj%%/.claude/*}"
  [ -d "$HOME/coding/$proj" ] || continue
  mkdir -p "$(dirname "$dst")" && cp -n "$src" "$dst" && echo "$rel"
done
```

Two live one level deeper and need a manual copy: `js/admin-ui/backend/.env` and
`php/jam/docker/.env`.

### 5d. The repos you can't clone

Twenty-two repos have no remote and no commits. They're the rust learning projects (`enums`,
`ownership`, `structs`, `teletype`, and so on), `js/codewars`, `pheonix/hello`, `rust/BunzBot`,
`rust/bunzboard`, and `mit`. Everything in them is untracked, so git can't help you move them.

Pick one:

- **Copy the ones you still care about.** rsync from `/mnt/c`, skipping build output:

  ```sh
  rsync -a --exclude target --exclude node_modules \
    /mnt/c/Users/austi/coding/rust/teletype ~/coding/rust/
  ```

  Then `git add -A && git commit` inside WSL so it's a real repo. Line endings will be CRLF from
  the copy, so run `git add --renormalize .` first if the project has a `.gitattributes`.

- **Leave them in `coding.old`.** Honest option for the exercises. They're a `cargo new` away.

Same deal for the non-git dirs (`unity/`, `godot/`, `elixir/`, the `codeforces` scratch). Unity and
Godot stay on Windows regardless, the tooling is Windows.

### 5e. Leave the Windows copy alone for a week

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

On this box that already prints `true`. Windows Node is in the WSL PATH, but after `/usr/bin`, so
bare `node` wins and only `node.exe` reaches across. Fine for the hook, still worth closing (see
the interop note below).

Install Claude Code inside WSL. Do step 8 first so `/login` can open a browser.

```sh
curl -fsSL https://claude.ai/install.sh | bash
claude
```

Inside Claude: `/login`, then `/hooks` to trust the four hooks, then `/mcp` to authenticate
atlassian and Matrixify. Then back in the shell, run the installer once more so it registers the
MCP servers it skipped in step 4, and verify:

```sh
cd ~/.config && bash install.sh
claude   # then /verify-settings, want all green
```

The Windows-side Claude keeps working the whole time. It's pointed at the Windows repo through
its own symlinks and doesn't know WSL exists. Uninstalling it is in the cleanup section at the end.

**PATH interop.** I'd turn it off on this box. Fifty-one Windows entries are appended to the WSL
PATH, and they put Windows Python, Java, Go, CMake, clang, Neovim, and Git one `.exe` away from
any script that guesses a name. wslview (step 8) covers the browser case, and VS Code's Remote-WSL
server provides its own `code` inside remote terminals, so the usual reason to keep it doesn't
apply.

```sh
sudo tee -a /etc/wsl.conf >/dev/null <<'CONF'

[interop]
appendWindowsPath = false
CONF
```

Then `wsl --shutdown` from PowerShell and reopen. `/etc/wsl.conf` already has a `[boot]` section
for systemd, hence the leading blank line. **The tradeoff:** you lose calling Windows exes by name
from inside WSL (`explorer.exe .`, `clip.exe`). Full paths under `/mnt/c` still work.

## 7. Point WezTerm at WSL

The Lua side is already done. `wezterm/wezterm.lua` does:

```lua
config.wsl_domains = wezterm.default_wsl_domains()
config.default_domain = 'WSL:Ubuntu'   -- or the first distro it finds
```

One wrinkle: the exact-match branch looks for `WSL:Ubuntu`, and this distro is `WSL:Ubuntu-24.04`.
It falls through to "first distro found", which is the right one because there's only one. If a
second distro ever shows up, make that match a prefix.

The real question is where the Windows WezTerm reads its config from once the Windows repo clone
stops being the source of truth. WezTerm is a Windows app, so it looks at
`%USERPROFILE%\.config\wezterm\wezterm.lua` or `%USERPROFILE%\.wezterm.lua`. Today that's this
repo. Rather than keep a second clone on `C:` that drifts, WezTerm reads the WSL copy through a
user environment variable. **`install.ps1` (step 2) sets this for you** once the WSL clone exists,
so on this box it's already done. The value it writes:

```
WEZTERM_CONFIG_FILE=\\wsl.localhost\Ubuntu-24.04\home\austin\.config\wezterm\wezterm.lua
```

If you ever need to set it by hand (a second distro, a fresh box before step 4), it's under
**Settings → System → About → Advanced system settings → Environment Variables → User**, or from
PowerShell:

```powershell
[Environment]::SetEnvironmentVariable('WEZTERM_CONFIG_FILE', '\\wsl.localhost\Ubuntu-24.04\home\austin\.config\wezterm\wezterm.lua', 'User')
```

Touching that path starts the distro on demand, so WezTerm works from a cold boot. Config
auto-reload may not fire over the 9p share, so `C-S-r` after edits. Every keybind, the doom-one
palette, and the Shift+Enter fix for Claude Code work unchanged.

Falls back to Nushell or pwsh if no distro is installed, so it won't break on a fresh box.

## 8. Browser handoff for OAuth

Claude Code's `/login` and any `xdg-open` need a way out to Windows. `xdg-utils` is installed here
but has nothing to hand off to.

```sh
sudo apt install -y wslu
wslview https://example.com   # should open your Windows browser
```

The installer's WSL2 health step warns if this is missing. Do this before step 6.

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
| `emacs` | WSLg frame, `SPC` tree works, `SPC p c` exists |
| `readlink -f ~/coding` | a `/home/...` path, **not** `/mnt/c` |
| `/verify-settings` in Claude | all green |
| WezTerm from a cold boot | opens straight into zsh in WSL |

---

## Stuff the installer won't do for you

The dotfiles installer covers the shell and editors. The repos need more than that, and the
Windows side had it all. What to put back in WSL, by what actually uses it:

| Tool | Used by | Install |
|------|---------|---------|
| maven | the JAM Java services | `sudo apt install -y maven` (OpenJDK 25 is already there) |
| gh | everything on GitHub | `sudo apt install -y gh && gh auth login` |
| Go | `go/ProLUG-Events` | `sudo apt install -y golang-go` or the tarball from go.dev |
| docker | `php/jam` (magento) | Docker Desktop with WSL integration, or `docker-ce` inside the distro |
| npm globals | JAM work | `npm i -g @shopify/cli @oracle/suitecloud-cli pnpm typescript typescript-language-server` |
| python venv | the python repos | `sudo apt install -y python3-venv python3-pip` |

The other Windows npm globals (openapi-generator-cli, redocly, json-schema-to-zod, opencode,
claude-code-acp) are install-on-demand. Windows keeps Unity, Godot, and dotnet.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Everything is slow, `git status` takes seconds | Files on `/mnt/c` | Move them into the WSL filesystem. Step 5 |
| Claude Code errors on every file edit | Windows `node.exe` in PATH | Step 6 |
| Audit loop says every repo is dirty | Ran it from WSL, CRLF over 9p | Run it from Git Bash on Windows. Step 5a |
| `git clone` in WSL says permission denied | keychain hasn't loaded `id_wsl` (non-interactive shell) | Open a real zsh, or `ssh-add ~/.ssh/id_wsl` |
| `bash install.sh` says MCP registration skipped | No `claude` binary yet | Expected. Re-run after step 6 |
| nvim file watching misses changes | inotify doesn't work over 9p | Same, files must be in ext4 |
| `wsl --install` says it needs a reboot | It does | Reboot, then re-run `install.ps1` |
| Treesitter parser installs fail | No C compiler | `sudo apt install build-essential` |
| Emacs opens in the terminal, paredit keys dead | No WSLg frame | Check `echo $DISPLAY` is set. `config.org:887` explains why those bindings need a GUI |
| `/login` never opens a browser | No `wslview` | Step 8 |
| WezTerm opens PowerShell, not WSL | No distro when WezTerm started | `wsl -l -v`, then `C-S-r` in WezTerm to reload |
| WezTerm ignores config edits | Auto-reload doesn't fire over `\\wsl.localhost` | `C-S-r` |

## Windows cleanup, later

Once `/verify-settings` is green in WSL and you've used it for a week, the Windows side can shed
what the doc says it shouldn't have. Your call on timing, none of it blocks the migration.

- Uninstall Windows Node: `winget uninstall OpenJS.NodeJS.LTS`. Takes the npm globals with it.
- Uninstall the Windows Claude Code binary at `C:\Users\austi\.local\bin\claude.exe`.
- Remove the `~/.claude` symlinks that point at `C:\Users\austi\.config\claude`. Once WezTerm reads
  from WSL (step 7), nothing on Windows needs the repo clone at all.
- The other winget packages (Neovim, ripgrep, fd, CMake, LLVM, rustup, nushell) can stay or go.
  They're harmless once PATH interop is off.

## Maintenance note

Once `coding.old` is deleted and this has stuck, this doc is done. Leave it in the repo anyway,
it's the runbook for the next Windows machine. The "where this box is right now" section is the
only part that goes stale; the rest is the general path.
