# Git

[← Back to the index](../CLAUDE.md)

`git/config` and `git/ignore`. Both are found natively, no symlinks, no `core.excludesFile`
setting. Git reads `$XDG_CONFIG_HOME/git/config` on macOS, Linux, and Windows (where `HOME` is
`%USERPROFILE%`), and its default excludes file is already `$XDG_CONFIG_HOME/git/ignore`, which is
the file sitting right next to the config.

## The ~/.gitconfig gotcha

Git reads `~/.gitconfig` *after* `~/.config/git/config`, so any single-valued key set in
`~/.gitconfig` silently overrides everything here. That's why `install.sh` deletes it during
`setup_git_config`.

If your settings ever stop taking effect, check whether something recreated `~/.gitconfig`. Plenty
of tools will happily write to it via `git config --global`.

## Settings

| Setting | Value | Why |
|---------|-------|-----|
| `init.defaultBranch` | `main` | |
| `branch.sort` | `-committerdate` | Most recent branches first in `git branch` |
| `tag.sort` | `version:refname` | Version-aware tag sort, so v10 comes after v9 |
| `column.ui` | `auto` | Multi-column output when the terminal is wide enough |
| `diff.algorithm` | `histogram` | Noticeably better diffs than the default myers |
| `diff.colorMoved` | `plain` | Moved blocks get colored differently from real changes |
| `diff.mnemonicPrefix` | `true` | `i/` `w/` `c/` prefixes instead of `a/` `b/` |
| `diff.renames` | `true` | Detect renames |
| `pull.rebase` | `true` | No merge commits from pulling |
| `push.default` | `simple` | |
| `push.autoSetupRemote` | `true` | First `git push` on a new branch just works, no `-u` |
| `push.followTags` | `true` | Annotated tags go along with the push |
| `rebase.autoSquash` | `true` | `fixup!` commits get squashed automatically |
| `rebase.autoStash` | `true` | Dirty tree doesn't block a rebase |
| `rebase.updateRefs` | `true` | Stacked branches get moved along with the rebase |

The rebase trio is the quality-of-life set. `autoStash` alone removes most of the "stash, rebase,
pop" ceremony, and `updateRefs` means a stack of dependent branches survives a rebase of the base
one instead of being left pointing at orphaned commits.

## Global ignore

`git/ignore` is currently one line:

```gitignore
**/.claude/settings.local.json
```

Per-machine Claude overrides, which should never end up in anyone's repo. Keep this file small.
Global ignores that get too opinionated cause the fun kind of bug where a file mysteriously
refuses to be added on one machine.

## Identity

`user.name` and `user.email` are set in `git/config`, which means they're the same on every
machine that clones this repo. If a specific repo needs a different identity (a work email, say),
set it locally in that repo rather than editing this file.
