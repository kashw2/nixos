---
name: rebase-dependabot
description: Rebase all open Dependabot pull requests against the base branch (origin/main). Use when Dependabot PRs have fallen behind main and need to be brought up to date, or when the user asks to "rebase dependabot", "update the dependabot PRs", or refresh stale dependency bumps before merging.
---

# Rebase Dependabot PRs

Trigger a rebase of every open Dependabot pull request against `main`. This uses Dependabot's own `@dependabot rebase` command, which rebases the PR branch server-side. This is preferred over a local checkout + force-push because Dependabot owns these branches: it resolves the rebase, re-runs its update logic, and force-pushes itself, avoiding conflicting force-pushes and lockfile drift.

## Steps

1. **List open Dependabot PRs.** Filter by the Dependabot bot author:

   ```bash
   gh pr list --author "app/dependabot" --state open --json number,title,headRefName --limit 100
   ```

   If the list is empty, report that there's nothing to rebase and stop.

2. **Ask the user which PRs to rebase.** Use the `AskUserQuestion` tool. Commenting `@dependabot rebase` is visible on GitHub and triggers CI on each PR, so always confirm scope here — even if the user already said "rebase dependabot", let them narrow it down.

   Build the question dynamically from the list in step 1:
   - **Header:** `Rebase scope`
   - **Question:** something like `Found N open Dependabot PRs. Which do you want to rebase against main?`
   - **First option (recommended):** `All Dependabot PRs` — rebase every PR from step 1.
   - **Remaining options:** include a few of the most relevant individual PRs (e.g. `nixpkgs (#147)`, `hyprland (#148)`) as quick single-PR picks, up to the 4-option limit.
   - The user can always pick "Other" to type a specific subset (e.g. `147, 148, 153`).

   Resolve the answer to a concrete list of PR numbers before continuing. If they picked specific numbers, rebase exactly those.

3. **Trigger the rebase on each selected PR.** For every PR number chosen in step 2:

   ```bash
   gh pr comment <number> --body "@dependabot rebase"
   ```

   Run these sequentially. Dependabot picks up each comment and rebases that branch against its base (`main`) asynchronously — the rebase does not complete the instant the comment posts.

4. **Report.** List which PRs were triggered (number + title). Note that Dependabot processes them asynchronously, so the branches will update over the next few minutes; the user can re-check with `gh pr list` or watch CI.

## Notes

- `@dependabot rebase` only rebases — it does not merge. If the user wants merges too, that's a separate step (`gh pr merge`), and should be confirmed independently.
- If a PR has conflicts Dependabot can't resolve, it comments on the PR saying so; surface that to the user if you spot it in a follow-up check.
- Other useful Dependabot comment commands if asked: `@dependabot recreate` (rebuild from scratch, discarding manual edits), `@dependabot merge`, `@dependabot close`.
- Avoid local `git rebase` + `git push --force` against `dependabot/*` branches: Dependabot may force-push over your work, and you'd be force-pushing branches you don't own.
