# Keanu Ashwell's NixOS Configuration

<div align="center">
	<img src="screenshots/desktop.png">
</div>
<br>

# Sops

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption. Each machine's SSH host key is converted to an age key for decryption, plus an admin age key for manual operations.

## Commands

```bash
# Edit encrypted secrets
nix-shell -p sops age --run 'sops secrets/secrets.yaml'

# Verify decryption works
nix-shell -p sops age --run 'sops --decrypt secrets/secrets.yaml'

# Get a machine's age public key
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# Re-encryption
nix-shell -p sops age --run 'sops updatekeys secrets/secrets.yaml'
```

## Adding a new machine

1. Get its age public key: `nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'`
2. Add the key to `.sops.yaml` under `keys` and in `creation_rules`
3. Re-encrypt: `nix-shell -p sops age --run 'sops updatekeys secrets/secrets.yaml'`
4. Add the host's SSH keys: `nix-shell -p sops age --run 'sops secrets/secrets.yaml'`
5. Import `self.nixosModules.sops` in the new host's configuration

# Nixos Anywehre

https://nix-community.github.io/nixos-anywhere/howtos/no-os.html
