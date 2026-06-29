# Global instructions

Personal, machine-agnostic guidance for Claude Code across all projects. Project-level
`CLAUDE.md` files always take precedence over anything here.

## Working style

- Be concise and direct. Lead with the answer, then the reasoning if it's needed.
- Match the conventions of the surrounding code — naming, comment density, structure — rather
  than imposing a personal style on someone else's codebase.
- Prefer reusing existing utilities over adding new ones. Look before you build.
- Don't commit, push, or take other hard-to-reverse actions unless asked.

## Environment & project layout

- Coding projects live at `~/coding/{language}/{project}` on every platform — e.g.
  `~/coding/js/netsuite-dash`, `~/coding/rust/foo`, `~/coding/python/bar`. Assume this layout
  when locating, referencing, or scaffolding a project.

## Git

- **Never add Claude as a commit co-author.** Do not append `Co-Authored-By: Claude ...`
  trailers, "Generated with Claude Code" lines, or any similar attribution to commit messages
  or PR descriptions.
- Don't commit or push unless explicitly asked (also noted under Working style).

## Style skills

- **`writing-code` — MANDATORY before writing or editing code in ANY language.** Always invoke
  it and read the matching `languages/<lang>.md` first. Never write code without it. (When
  editing a codebase with its own established conventions, those still win over personal style.)
  If the project depends on `@jambnc/common` or `@jam/schemas`, also invoke **`jam-plus`**.
- **`writing-docs`** — invoke when writing or revising documentation, READMEs, guides, commit
  messages, or other prose. Applies the personal documentation voice and structure.
