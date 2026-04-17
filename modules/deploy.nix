# Remote-install wrapper around nixos-anywhere for hosts that use
# impermanence + sops-nix.
#
# Why this exists: a bare `nixos-anywhere --flake .#<host>` run installs
# the system, but first-boot activation fails with
#
#     sops-install-secrets: cannot read keyfile '/persist/var/lib/sops-nix/key.txt'
#     Activation script snippet 'setupSecretsForUsers' failed
#     warning: password file '/run/secrets-for-users/keanu_password' does not exist
#
# because modules/features/sops.nix reads its age key and ed25519 SSH
# host key directly from /persist (to avoid a stage-2 race with the
# impermanence bind mounts), and /persist is empty on a fresh install.
#
# The fix is to seed those files into /persist *before* activation via
# nixos-anywhere's --extra-files flag, which copies a local tree onto
# the target's root. Two non-obvious details this wrapper handles:
#
#   1. The staging tree must use the `persist/` prefix. /persist is a
#      separate btrfs subvolume (modules/hosts/<host>/disko.nix) that
#      survives the rollback-root initrd wipe; files placed at plain
#      /etc/ssh/... would land in the root subvolume and get wiped on
#      first boot.
#
#   2. Staging files stay owned by the current user, not root.
#      nixos-anywhere's source-side tar runs as the invoking user and
#      fails with `tar: Permission denied` on root-owned 0400/0600
#      files. Restrictive modes are preserved; on-target ownership is
#      set by nixos-anywhere.
#
# The USB layout matches modules/installer.nix's install-host so the
# same stick works for both ISO-based and over-the-network installs.
{ self, inputs, ... }:
let
  hosts = [
    "home"
    "laptop"
    "thinkpad"
    "media"
  ];
in
{
  perSystem =
    { pkgs, lib, ... }:
    let
      deployHost = pkgs.writeShellApplication {
        name = "deploy-host";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.nix
        ];
        text = ''
          set -euo pipefail

          HOST=""
          IP=""
          PATH_USB=""

          usage() {
            cat >&2 <<EOF
          Usage: deploy-host --host <name> --ip <ip-or-hostname> [--path <usb-root>]

          Remote-reinstall a host via nixos-anywhere, seeding /persist with the
          sops age key and ed25519 host key from a USB so sops-nix can decrypt
          secrets on first boot.

          Flags:
            --host <name>      host attribute in flake.nixosConfigurations.
                               Known hosts: ${builtins.concatStringsSep ", " hosts}.
            --ip <addr>        target IP or hostname. The target must be booted
                               into the NixOS minimal installer with a password
                               set for 'root' (run 'sudo passwd root' on the
                               installer console). Connection is always made as
                               root — the installer's nixos user doesn't have
                               passwordless sudo configured for nixos-anywhere's
                               remote operations.
            --path <usb-root>  path to the mounted key USB root. Defaults to the
                               first directory under /run/media/\$USER.

          Expected USB layout (matches install-host in modules/installer.nix):
            <usb-root>/sops/admin/keys.txt
            <usb-root>/sops/<host>/ssh_host_ed25519_key
            <usb-root>/sops/<host>/ssh_host_ed25519_key.pub
          EOF
            exit 1
          }

          while [ $# -gt 0 ]; do
            case "$1" in
              --host) HOST="$2"; shift 2 ;;
              --ip) IP="$2"; shift 2 ;;
              --path) PATH_USB="$2"; shift 2 ;;
              -h|--help) usage ;;
              *) echo "Unknown flag: $1" >&2; usage ;;
            esac
          done

          [ -n "$HOST" ] || { echo "Missing --host" >&2; usage; }
          [ -n "$IP" ] || { echo "Missing --ip" >&2; usage; }

          if [ -z "$PATH_USB" ]; then
            PATH_USB=$(find "/run/media/$USER" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | head -n1 || true)
            [ -n "$PATH_USB" ] || { echo "No USB found under /run/media/$USER; pass --path explicitly" >&2; exit 1; }
            echo "Auto-detected USB at $PATH_USB"
          fi

          KEY_SRC="$PATH_USB/sops/admin/keys.txt"
          SSH_KEY_SRC="$PATH_USB/sops/$HOST/ssh_host_ed25519_key"
          SSH_PUB_SRC="$PATH_USB/sops/$HOST/ssh_host_ed25519_key.pub"
          for f in "$KEY_SRC" "$SSH_KEY_SRC" "$SSH_PUB_SRC"; do
            [ -f "$f" ] || { echo "Missing expected file: $f" >&2; exit 1; }
          done

          STAGING=$(mktemp -d "/tmp/''${HOST}-bootstrap.XXXXXX")
          cleanup() {
            if [ -f "$STAGING/persist/var/lib/sops-nix/key.txt" ]; then
              shred -u "$STAGING/persist/var/lib/sops-nix/key.txt" || true
            fi
            rm -rf "$STAGING"
          }
          trap cleanup EXIT

          # Mirror-to-target layout: paths under $STAGING land at the same
          # relative paths on the installed root. The persist/ prefix is
          # required — /etc/ssh/... directly would be wiped on first boot by
          # the rollback-root initrd service. Files stay owned by the current
          # user so nixos-anywhere's source-side tar can read them.
          install -D -m 0400 "$KEY_SRC"     "$STAGING/persist/var/lib/sops-nix/key.txt"
          install -D -m 0600 "$SSH_KEY_SRC" "$STAGING/persist/etc/ssh/ssh_host_ed25519_key"
          install -D -m 0644 "$SSH_PUB_SRC" "$STAGING/persist/etc/ssh/ssh_host_ed25519_key.pub"

          echo "Staging tree at $STAGING:"
          find "$STAGING" -printf '  %M %p\n'
          echo

          # --phases disko,install,reboot skips kexec (target is already in
          # the installer). Loose host-key options tolerate the fresh
          # installer host key without touching ~/.ssh/known_hosts.
          echo "Invoking nixos-anywhere..."
          NIXPKGS_ALLOW_UNFREE=1 exec nix run github:nix-community/nixos-anywhere -- \
            --flake ".#$HOST" \
            --target-host "root@$IP" \
            --build-on local \
            --phases disko,install,reboot \
            --extra-files "$STAGING" \
            --ssh-option StrictHostKeyChecking=no \
            --ssh-option UserKnownHostsFile=/dev/null \
            --option pure-eval false
        '';
      };
    in
    {
      packages.deploy-host = deployHost;
    };
}
