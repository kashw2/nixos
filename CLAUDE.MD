# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS flake-based configuration managing three hosts (home, laptop, thinkpad) with Colmena deployment. Uses flake-parts and import-tree for modular organization.

## Build & Deploy Commands

```bash
# Enter dev shell (provides colmena, nix, git)
nix develop

# Deploy to all hosts
colmena apply

# Deploy to a specific host
colmena apply --on home
colmena apply --on laptop
colmena apply --on thinkpad

# Build a specific host configuration without deploying
nix build .#nixosConfigurations.home.config.system.build.toplevel
nix build .#nixosConfigurations.laptop.config.system.build.toplevel

# Check flake outputs
nix flake show

# Update flake inputs
nix flake update
```

## Architecture

### Dendritic Pattern

This repo follows the [dendritic pattern](https://github.com/mightyiam/dendritic). Every Nix file under `modules/` (except entry points) is a top-level flake-parts module, auto-imported via `import-tree`. Each file implements a single feature across all applicable configurations (NixOS, home-manager, etc.). Files are path-independent — they can be freely renamed or reorganized without breaking functionality. Lower-level configurations (e.g., NixOS, home-manager) are stored as option values using `deferredModule` type.

### Flake Structure

- **flake-parts** organizes outputs; **import-tree** auto-imports everything under `./modules`
- **nix-wrapper-modules** (`wrapper-modules` input) defines wrapped packages with embedded config files
- Single system target: `x86_64-linux`

### Module Layout (`modules/`)

- **`hosts/`** — Per-machine configs (hardware, disko partitions, GPU drivers). Each host imports the same ordered set of feature modules.
- **`features/`** — Reusable NixOS modules: `environment.nix`, `nix.nix`, `security.nix`, `networking.nix`, `audio.nix`, `virtualisation.nix`, `sops.nix`
- **`features/desktop-environment/`** — Hyprland WM, SDDM display manager, hyprlock, hypridle, hyprpaper. Most are **wrapper** modules.
- **`features/nixvim/`** — Neovim config split across: `default.nix` (core), `plugins.nix`, `lsp.nix`, `keymaps.nix`, `colorschemes.nix`, `highlights.nix`
- **`users/keanu/`** — User config, home-manager programs, system packages, SSH authorized keys
- **`colmena.nix`** — Deployment targets for all three hosts (home.local, laptop.local, thinkpad.local)
- **`secrets/`** — SSH host keys per machine; SOPS-encrypted secrets in `secrets/secrets.yaml`

### Wrapper Modules Pattern

Desktop/shell programs use `flake.wrappers.<name>` from nix-wrapper-modules to create packages with baked-in configuration files. These are defined in their respective feature files (e.g., `nushell.nix`, `kitty.nix`, `hyprland.nix`) and exposed as `self.packages.${system}.<name>`.

### Host Differences

- **home**: AMD desktop, AMDGPU, dual NIC (ethernet + WiFi), GRUB boot
- **laptop**: Intel+NVIDIA hybrid GPU (NVIDIA prime), dual NIC
- **thinkpad**: AMD laptop, WiFi-only, Bluetooth enabled

All hosts share the same module import order and user configuration. Host-specific differences are in hardware configs and disko partition layouts.

### Secrets Management

Uses sops-nix with age encryption.

## Conventions

- Modules use `flake.nixosModules.<name>` namespace via flake-parts
- Custom packages use `perSystem.packages.<name>`
- Home-manager is integrated at the system level (not standalone)
- Nushell is the default shell (not bash/zsh)
- All hosts deploy via Colmena over SSH to `<hostname>.local`
