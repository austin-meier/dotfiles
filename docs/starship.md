# Starship prompt

[← Back to the index](../CLAUDE.md)

`starship.toml` at the repo root. Starship reads `~/.config/starship.toml` by default, so there's
nothing to configure beyond having the file here.

The prompt is deliberately boring. One line, no newline before it, and it only shows things that
change:

```
format = "$directory$git_branch$git_status$cmd_duration$character"
```

Directory, branch, dirty state, how long the last command took, and the prompt character. That's
it.

## What's turned off, and why

`package`, `username`, `hostname`, `time`, `nodejs`, `bun`, `rust`, `python`, `java`: all disabled.

Language version modules are the main offender. I know what Node version I'm on, and if I don't,
`node -v` is right there. Rendering it on every single prompt costs latency for information I look
at maybe once a day. Hostname is redundant because the [WezTerm](wezterm.md) status bar already
shows it.

## The segments

| Segment | Behavior |
|---------|----------|
| `directory` | Bold blue, truncated to 3 components, truncates to the repo root |
| `git_branch` | Violet, ` ` symbol, branch names capped at 24 chars |
| `git_status` | Yellow, counts instead of symbols (`!3` not `!!!`) |
| `cmd_duration` | Grey, only appears past 2 seconds |
| `character` | Green `❯` on success, red `❯` on failure, violet `❮` in vi normal mode |

The git status counts are the useful part: `+2!3?1` tells you 2 staged, 3 modified, 1 untracked at
a glance, instead of a wall of identical symbols.

`cmd_duration` at `min_time = 2_000` means it stays quiet for normal commands and only shows up
when something actually took a while.

## Directory substitutions

```toml
[directory.substitutions]
"~/Documents/lampblack" = "󱓛 lampblack"
"~/coding"              = " coding"
```

Two paths I'm in constantly get a short icon-prefixed name instead of the full path. Add more here
as needed.

## Palette

The `doom_one` palette is defined inline at the top of the file and referenced by name. Same hex
values as [WezTerm](wezterm.md) and the fzf colors in [zsh](zsh.md). If you change the theme,
change it in all three or things will look subtly off.
