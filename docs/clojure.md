# Clojure

[← Back to the index](../CLAUDE.md)

Barely anything, honestly, but it's tracked so a new machine gets a working `clj` immediately
instead of a first-run surprise.

## deps.edn

```clojure
{:aliases {}}
```

The user-level `deps.edn`, which lives at `~/.config/clojure/deps.edn` and gets merged under the
root `deps.edn` for every project on the machine. Cross-project aliases go here: things you want
available in *any* project (a REPL alias, a formatter, a linter) rather than in that project's own
`deps.edn`.

It's empty for now. That's the correct starting state, since anything that belongs to a project
belongs in the project.

## tools/tools.edn

```clojure
{:lib io.github.clojure/tools.tools
 :coord {:git/tag "v0.3.8"
         :git/sha "fd43f6e927fe1b1635c063b3e18745bd46ecec33"}}
```

The [tools.tools](https://github.com/clojure/tools.tools) installation, pinned by tag and SHA.
That's what makes `clj -Ttools list` / `install` / `remove` work, which is how you install other
`-T` tools. Tracking it means the tool manager itself is reproducible instead of being whatever
version you happened to bootstrap with.

`.cpcache` directories are gitignored, since those are just classpath caches.

## Editor support

The actual Clojure development experience is in the editors, not here:

- [Emacs](emacs.md): CIDER, plus lispyville and paredit for structural editing
- [Neovim](nvim.md): conjure for the REPL, nvim-paredit for structural editing, clojure-lsp via
  mason

Both have rainbow-delimiters, because unbalanced parens are a self-inflicted wound.
