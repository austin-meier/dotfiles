---
name: writing-code
description: The user's personal code style. MUST be used whenever writing or editing code in ANY language - invoke it, then read the matching languages/<lang>.md before producing code. Covers functional/immutable style, naming, the zero-comments rule, architecture, Node-over-Python for project scripts, verifying before reporting done, and per-language idioms.
---

# Writing code in my style

Applies to new code in my own projects. When editing a codebase with its own established
conventions, those win.

## Cross-language principles

1. **Functional & immutable, Clojure-inspired.** Pure functions. No mutation, return new values.
   Side effects at the edges.
2. **Composition over inheritance, always.** Compose functions and data, not class hierarchies.
3. **Iteration via higher-order functions.** `map` / `filter` / `reduce` / `forEach` and sequence
   helpers over `for` / `while`.
4. **Absence is `undefined`/nil, never `null`.** Clojure nil-punning. In languages with both,
   never produce `null` and never write `=== null`. In Java, `Optional`.
5. **Business logic lives in a `lib`-style core, entry points are thin.** Routes, handlers,
   controllers, and `main` load data, call `lib`, return results. Nothing else.
6. **Zero comments.** Names and decomposition do the documenting. Full rule below.
7. **Reach for the curated toolset before writing a helper.** The per-language file says where it
   lives.

## Comments: don't write them

**Zero. Not sparse, not brief, not "just this one for clarity."**

This is the rule I care about most and the one you're most likely to break, because you're trained
to emit comment tokens. Notice the urge and don't act on it. If code feels like it needs an
explanation, **restructure or rename** until it doesn't. A long, precise name travels with the
value. A comment rots the second someone edits the line under it.

| What you were about to write | Do instead |
|------|------|
| `/* Calculate the total for the cart */` | Name it `calculateCartTotal`. The comment was the function name |
| `/* Loop over users and drop inactive ones */` | `const activeUsers = users.filter(isActive)` |
| `/* Step 1: validate. Step 2: persist. */` | Extract each step into a named function |
| `/* Fixed the bug where id was undefined */` | Nothing. That's what git blame and the commit message are for |
| `/* --- Helpers --- */` | Nothing. A file that needs section dividers needs splitting |
| `// eslint-disable-next-line`, `#[derive(...)]` | Fine. Directives aren't comments |

**Never:**

- Narrate what the code does, restate a signature, or label a section.
- Write JSDoc, docstrings, or `///` doc comments, unless the codebase already has them on everything.
- Explain the edit, the bug, or why the old approach failed. That goes in your reply, not my file.
- Leave a `// TODO`. Tell me instead.
- Re-add a comment I deleted, or keep one you wrote earlier this session.

**Comments already in the file are mine.** Leave them alone, and don't read their presence as
permission to add your own.

**The one exception isn't yours to take.** If you write something genuinely cursed (a workaround
for an upstream bug, an ordering dependency that looks arbitrary), say so in your reply and note
that I may want to comment it. I decide, and I write it. The bar: a competent developer with full
context would still get it wrong and burn hours on it. Nothing routine clears that bar.

The `comment-guard` hook rejects any edit containing a comment. It's a backstop. The rule is above.

## Scripts are Node, not Python

Any script that lands in a project (build tooling, migrations, codegen, seeding, CI helpers,
scrapers, one-off maintenance) is a `.ts` or `.mjs` file run with Node. Most of my projects are
Node, and I don't read Python outside AI/ML work.

- Node >= 22.18 runs `.ts` directly via type stripping: no build step, no dependencies.
- The standard library covers what you'd have used Python for: `node:fs`, `node:path`,
  `node:child_process`, `node:readline`, `fetch`, `node:sqlite`, `node:test`.
- Same style rules apply. A script is code, not a scratchpad.
- AI/ML is the exception: numpy, pandas, pytorch, or a Python-only library. Say so and move on.
- An existing Python project stays Python. Established conventions win.

In-session tool use isn't a script. `python3` inside a Bash call during our conversation is fine.
The rule is about files that live in a repo.

## Testing pure functions

- When you add pure functions and the project allows it, write tests for them.
- No test runner? Set one up with a runnable `test` script (`npm test`, `cargo test`, equivalent).
- Prefer inline tests where the language does them well (Rust `#[cfg(test)]`). Otherwise a simple
  `test/` directory, grouped logically.
- Built-in or lightweight runner first. A library has to earn its place.

## Done means verified

Before you report a change as finished:

- **Diagnostics are clean.** If an LSP tool is available for the language (TypeScript, Rust, and
  C/C++ are wired up), check every file you touched. Otherwise run the type checker or compiler.
- **Tests ran, and you ran them.** Say what you ran and what it printed. Never report a passing
  suite you didn't execute.
- **Anything you couldn't verify, say so first.**

## Per-language files

Read the matching file after this one. Only `languages/typescript.md` exists today (TS/JS). For
any other language the principles above are the whole guide; follow that language's own idioms
for everything they don't cover.

If the project depends on `@jambnc/common` or `@jam/schemas`, also invoke the `jam-plus` skill.
