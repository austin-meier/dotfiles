---
name: writing-docs
description: Write or revise documentation (READMEs, guides, Confluence, internal code docs, design notes) in the user's personal voice - approachable, conversational, honest, lightly funny. Use whenever authoring or revising human-facing prose, and especially when the user says things like "use my doc writing skill". The goal is that it sounds like the user wrote it, not like generic AI docs.
---

# Writing docs in my voice

The whole goal: it should sound like I wrote it. Approachable, natural, and simple, like I'm
explaining the thing to a coworker leaning over my desk. Not stiff, not corporate, not AI-flavored.

## The core sound

- First person and direct. Talk to the reader as "you." Use "I" for things I personally built and
  for my opinions; use "we" for team decisions, project conventions, and shared practice.
- Honest and opinionated. Name tech debt, weak tools, and forced decisions plainly, and always give
  the *why*, especially when the decision got forced on us.
- Approachable over formal. Contractions always. Plain words. Short punchy sentences mixed in with
  the longer explaining ones.
- Funny when it earns it (see the calibration below). Where the content is pure reference, stay dry
  and tight.

## Procedures: the main thing I document

The most common reason I write docs is procedures I'll come back to later, so treat these as a
first-class doc type and make them quick, simple, and easy to follow.

- Format procedures as **ordered steps**, with **simple tables** and **bullets** wherever they help.
  Keep them short and skimmable. The reader should be able to glance at it and just do the thing.
- Lead with the goal in a sentence, then the steps. Include the exact commands, console paths, and
  values to use. Light on prose, heavy on "do this, then this."
- Document the **major, common, clear recurring tasks** a project will actually go through. For
  example:
  - "Updating keys when they expire"
  - "Adding a new user"
  - "Deleting or deactivating a user"
  - "Adding your key to NetSuite"
- **Don't over-document.** Skip trivial, obvious, or one-off procedures nobody will look up. If a
  proc isn't a real recurring task someone will come back for, leave it out. Better to have a few
  clear, high-value guides than a pile of noise.

For the full procedure playbook (opening shape, bold menu breadcrumbs, destructive-op safety,
runbook dispatch pages, with real examples from my Confluence), see `references/procedures.md`.

## Humor and edge: calibrate to the audience

Three tiers, from loosest to most reserved:

1. **Personal projects (just mine).** Full personality. Blunt jabs and light profanity are welcome.
   Loosest register, write it how I'd say it.
2. **Internal / team docs** (internal code documentation, internal project READMEs). Full
   personality. Blunt jabs and light profane words are fine. This is the home turf of the voice.
3. **Public-facing** (Confluence, open source, customer or partner facing). Keep my tone but lighter.
   Sarcasm and light jabs are good when they build approachability and friendliness for the reader.
   Keep blatant or heavy profanity ("fuck" and friends) near zero. Lean warm and welcoming. On
   Confluence specifically my voice stays honest and approachable: candid asides about tech debt,
   friendly "if you're unsure just ask a dev" guardrails, and the occasional wry "you get to..."
   are all on-brand, just with the humor dialed down from the internal-repo level.

Two rules that hold across every tier:

- **Humor scales with how painful the subject is.** Pure reference (commands, settings, ordered
  steps) stays tight and mostly straight. Overviews, "how this works," context sections, and
  anything involving tech debt or a decision forced on us is where the personality comes out.
- **Jabs aim at tech, tools, and situations, never at people.** Roast the framework, not a teammate.

If you genuinely can't tell the audience, ask, or default to the more reserved tier.

## Devices

- **Analogies are seasoning, not the meal.** One good analogy to make a hard idea click is great
  ("it's essentially another Java story"). Don't stack them.
- **Imagined-reader pushback** ("you might think X, and you'd be right, except..."). Use this
  rarely, only when it actually clarifies a confusing point. It's not a crutch.
- **Link out generously** to good authoritative sources (MDN, library docs, real guides) whenever I
  name a tool or concept. Teach by pointing people at the right source.
- Self-aware asides are fine in tiers 1 and 2 ("hahahaha tech debt", "Next question please").

## Mechanics

- **No emdashes, ever.** I don't use them naturally. Use commas, parentheses, periods, or just
  restructure the sentence. If old docs have them, that wasn't me.
- Contractions always (it's, don't, you'll, we're).
- Sentence-case headings. Use `#` / `##` / `###`.
- Numbered lists for ordered steps (repeated `1.` in markdown is fine). Bullets for unordered.
- Reference tables for settings, flags, mappings, entry points.
- Fenced code blocks with a language tag. Show the actual command, and explain the why around it.
- Bold for key actions and terms (**Edit**, **To set this up:**). Blockquotes for callouts and
  side notes.
- Write clean prose. My real docs have the odd typo. Keep the voice, not the typos.

## Structure

- Default to a single README/file for small or single-topic docs.
- **Split into a TOC-style README plus a `documentation/` folder when a section is a clearly
  separable, reusable chunk** that other docs (or people) could reference on its own. The point is
  staying DRY and scalable: write the in-depth piece once, then link people to it instead of
  repeating myself.
- Organize the `documentation/` folder by area (`setup/`, `deployment/`, `tools/`, `css/`, `intro`,
  ...). Each sub-doc opens with a `# Title` and a link back to the table of contents.
- **Ask me per project before fragmenting.** If the project already has fragmented docs (a
  `documentation/` folder, a TOC-style README), ask whether to keep breaking new pieces out into
  their own abstract docs. Don't unilaterally restructure an established layout.

## Examples (my actual voice)

Internal overview, full personality:
> This is a node.js React Router 7 application. You might think "oh react is a frontend application"
> and you would be right except React Router decided to slam in Remix and now it's a full-stack
> framework that's honestly an abomination but I digress.

Reference, tight and straight (no jokes needed):
> Since we don't want to always automatically pull in new schema changes as that could cause chaos,
> we have a command to update the npm jam types/schema package. To update the types: `npm run pull-types`

Honest reasoning behind a forced choice:
> Modern ES6 React has taken over the frontend market. There are plenty of flaws with it, it's not
> my favorite thing, but it's here to stay and has enterprise support. So to keep reliable, stable
> support, we decided a TypeScript React frontend is the right call.

What not to do:
- No emdashes.
- Don't open a reference or how-to doc with a comedy routine. Save personality for overviews and context.
- Don't stack analogies or lean on the "you might think..." move over and over.
- Don't carry heavy profanity into team or public docs.
- Don't aim jabs at people.

## References

- `references/procedures.md`: the procedure playbook (my most common doc type), covering opening shape,
  bold menu breadcrumbs, code/SQL conventions, destructive-op safety, and runbook dispatch pages,
  with real examples pulled from my Confluence.
