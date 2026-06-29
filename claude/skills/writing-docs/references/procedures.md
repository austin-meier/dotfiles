# Writing procedures (my most common doc)

Procedures are the docs I come back to most, so they get extra care. A good proc is something
someone can open mid-incident and just follow without thinking hard.

## Shape of a procedure

1. **Open with the trigger and the goal.** One or two sentences: when does this happen, and what
   are we about to do. Real examples from my docs:
   > If for some reason a design/print job failed to post to a vendor, or you need to repost the
   > order with data updates made, use the following process to make NetSuite forcibly repull the
   > design details from Magento and send the order to the vendor.

   > We occasionally get spam quotes from various bots that throw off prepress workflows. More than
   > likely someone at PrePress will let you know, and it's easiest for us to clean them up directly
   > in the database.
2. **Then the steps**, as ordered imperative actions ("Navigate to...", "Scroll down until you see
   the Support link, click it", "Click Edit to open the record"). Nest sub-steps under a step when
   it helps.
3. Show the exact thing to do, not the theory. Where a screenshot makes a UI step obvious, include
   one, or at least say what the reader should be looking at.

## Conventions in basically all my procs

- **Menu navigation as bold arrow breadcrumbs:** `**Sales → Quotes → All Active**`,
  `**Stores → Configuration → Print Configurators → Chili Configurator → Blocked Quote Terms**`.
- **Code/SQL in fenced blocks with inline comments and placeholders:**
  ```sql
  -- count first, by name
  SELECT COUNT(*) FROM kadro_customer_print_jobs
  WHERE print_id > 1624896 AND firstname = 'fakeFirstName';
  ```
  Use `<PLACEHOLDER>` style for values the reader swaps in.
- **Friendly guardrails.** Tell people when to slow down or ask. "If you have any concerns or
  questions just ask the dev team for clarification." "If you do not have an account linked with
  your @jamplus.com email, please let another dev know."
- **Light honest asides are fine.** Noting tech debt in passing is on-voice ("Unfortunately our
  print job table is massive and is still WIP to get slimmed down"). Don't let it derail the steps.

## Destructive procedures get extra care

When a proc changes or deletes production data:

- **Verify before you destroy.** Put the check queries first and say what a safe result looks like
  ("-- Should be empty", "verify no active sales are tied to this quote before deleting").
- **Bold or caps the danger.** "We can't really delete a real order without implications so
  **DON'T** delete any print job quotes attached to orders."
- Push people to be as narrow and precise as they reasonably can before the destructive step.
- Add a **maintenance note at the end** so the doc stays useful next time (e.g. "after cleanup,
  grab the latest id and update the queries above to set the starting window for next time").

## Runbook dispatch / index pages

For operational runbooks, a top page that maps symptom → procedure is gold. My "HOW TO BE NINJA"
page does this with a "Common Problem Dispatch" list:

> - You get messaged about excess or fake quotes that need cleaned up. → [Remove spam quotes]
> - A Folders.com design can't be saved and you see `No such entity with addressId` →
>   [Customer Default Billing/Shipping Sync Procedure]

Write these as "when you see X → go here" so someone can scan straight to their situation.
