# Terraform

Infrastructure that lives outside the NixOS closure but that the configuration depends on — chiefly credentials the hosts need in sops before they will start.

Run these with [OpenTofu](https://opentofu.org), not Terraform. State is encrypted with OpenTofu's native state encryption, which Terraform cannot read.

```bash
nix shell nixpkgs#opentofu
```

`pkgs.opentofu` is also installed for `keanu` on non-server hosts.

## Directories

- [`oneuptime/`](./oneuptime/README.MD) — `Server` monitors for the infrastructure agent, the Alloy telemetry ingestion key, and the runner registration.
