# Pull Request Standards

- **Title** — short and concise. Follow the same [Conventional Commits](https://www.conventionalcommits.org/) format as commit messages: `<type>(<optional scope>): <description>`.
- **Description** — only a small summary of the change. Keep it brief; don't pad it with test plans, checklists, or restated diffs.

## Examples

Good:

```
Title: ci: remove cache-nix-action from workflows

Removes the nix-community/cache-nix-action steps from all four CI
workflows; Attic and Cachix remain for caching.
```

```
Title: feat(hyprland): add floating rule for pavucontrol

Adds a windowrule so pavucontrol opens floating instead of tiled.
```

Bad:

```
# Title too long / not concise
Title: feat(hyprland): add a new windowrule that makes pavucontrol open as a floating window instead of being tiled in the layout

# Description too long — restates the diff, adds checklists
Description:
This PR changes line 42 of hyprland.nix to add a windowrule...
- [ ] Tested locally
- [ ] Updated docs
...
```
