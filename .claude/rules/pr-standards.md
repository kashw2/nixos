# Pull Request Standards

- **Title** — a short, concise title describing the changes at a high level. Do **not** use the Conventional Commits format (no `type(scope):` prefix); write it in plain language.
- **Description** — only a small summary of the change. Keep it brief; don't pad it with test plans, checklists, or restated diffs.

## Examples

Good:

```
Title: Remove cache-nix-action from CI workflows

Removes the nix-community/cache-nix-action steps from all four CI
workflows; Attic and Cachix remain for caching.
```

```
Title: Float pavucontrol windows

Adds a windowrule so pavucontrol opens floating instead of tiled.
```

Bad:

```
# Uses the conventional commit format
Title: ci: remove cache-nix-action from workflows

# Title too long / not concise
Title: Add a new windowrule that makes pavucontrol open as a floating window instead of being tiled in the layout

# Description too long — restates the diff, adds checklists
Description:
This PR changes line 42 of hyprland.nix to add a windowrule...
- [ ] Tested locally
- [ ] Updated docs
...
```
