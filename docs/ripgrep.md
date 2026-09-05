# ripgrep

[← Back to the index](../CLAUDE.md)

Five lines in `ripgrep/config`. ripgrep doesn't look for a config file on its own, it reads
whatever `RIPGREP_CONFIG_PATH` points at, and [the zshrc](zsh.md) sets that to
`$XDG_CONFIG_HOME/ripgrep/config`.

```
--smart-case
--hidden
--glob=!.git
--glob=!node_modules
--glob=!.DS_Store
```

| Flag | Why |
|------|-----|
| `--smart-case` | Lowercase search is case-insensitive, add a capital and it goes case-sensitive. The behavior you want ~100% of the time |
| `--hidden` | Search dotfiles. Kind of important in a dotfiles repo |
| `--glob=!.git` | `--hidden` would otherwise drag the entire object database into every search |
| `--glob=!node_modules` | Self-explanatory to anyone who has grepped a JS project once |
| `--glob=!.DS_Store` | macOS confetti |

`.gitignore` is still respected by default, so this is purely on top of that.

## Overriding it

Flags here are just prepended to your command line, so anything you pass wins:

```sh
rg --case-sensitive foo      # beats --smart-case
rg --no-ignore-vcs foo       # search gitignored files too
rg -u foo                    # or just go full unrestricted
```

To bypass the config entirely for one command: `RIPGREP_CONFIG_PATH= rg foo`.
