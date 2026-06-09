# Commit Standards

- **Conventional Commits** — format every commit message as `<type>(<optional scope>): <description>`, where `type` is one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`. See https://www.conventionalcommits.org/.
- **Atomic commits** — each commit represents one logical, self-contained change. Don't bundle unrelated changes together; split them into separate commits.

## Examples

Good — conventional and atomic:

```
feat(hyprland): add windowrule for floating pavucontrol
fix(nix): force security.wrappers.Hyprland.source to compositor binary
ci: remove nix-community/cache-nix-action from workflows
docs(claude): add commit standards rule
refactor(features): split telemetry into host and client roles
chore(deps): bump nixvim flake input
```

With a body and footer (breaking change):

```
feat(disko): switch home host to btrfs subvolume layout

Replaces the flat ext4 partition with @, @home, and @nix subvolumes
to enable impermanence.

BREAKING CHANGE: requires a reinstall; disko changes don't apply to
running systems.
```

Bad:

```
# Not conventional — no type prefix
update stuff

# Not atomic — bundles unrelated changes
fix: patch hyprland binds, bump nixpkgs, and rewrite the CI workflows

# Vague description
chore: changes
```
