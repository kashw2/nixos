{ self, inputs, ... }:
{
  flake.nixosModules.impermanence =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.impermanence;
    in
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
      ];

      options.impermanence = {
        rootDevice = lib.mkOption {
          type = lib.types.str;
          example = "/dev/disk/by-partlabel/disk-main-root";
          description = ''
            Block device of the top-level btrfs filesystem that holds the
            `root`, `home`, and `persist` subvolumes. Mounted with
            `subvol=/` in the initrd to perform the pre-boot wipe.
          '';
        };

        rootDeviceUnit = lib.mkOption {
          type = lib.types.str;
          example = "dev-disk-by\\x2dpartlabel-disk\\x2dmain\\x2droot.device";
          description = ''
            systemd device unit name for `rootDevice`, used to order the
            rollback service after the device becomes available.

            Derivation rule: drop the leading `/`, replace every path
            separator `/` with `-`, and escape any `-` that was already
            in the original path as `\x2d` (so it isn't confused with the
            separator replacement). Append `.device`.

            Worked example for `/dev/disk/by-partlabel/disk-main-root`:
              dev-disk-by\x2dpartlabel-disk\x2dmain\x2droot.device

            In a nix double-quoted string each `\` must itself be
            escaped, so write `\\x2d`. You can also generate it at
            install time with:
              systemd-escape -p --suffix=device /dev/disk/by-partlabel/...
          '';
        };
      };

      config = {
        # /persist holds the sops-nix age decryption key (the persisted
        # /etc/ssh/ssh_host_ed25519_key) and the hashed user passwords that
        # sops writes during early activation — must be up in stage 1.
        fileSystems."/persist".neededForBoot = true;

        # Read the sops age decryption key from its persistent location
        # rather than /etc/ssh. The impermanence `files` bind mount that
        # puts the key at /etc/ssh/ssh_host_ed25519_key is a stage-2
        # systemd unit and can race the sops `neededForUsers` activation
        # step on fresh boots when it loses, decryption silently fails
        # and users with hashedPasswordFile end up passwordless.
        # Hosts without impermanence keep the default /etc/ssh path set
        # in modules/features/sops.nix.
        # TODO: Upon full impermanence rollout remove this and make it the default in sops.nix
        sops.age.sshKeyPaths = lib.mkForce [
          "/persist/etc/ssh/ssh_host_ed25519_key"
        ];

        # /home is an ephemeral mount used as a target for home.persistence
        # bind mounts; impermanence requires it be marked neededForBoot.
        fileSystems."/home".neededForBoot = true;

        # Log subvolume also wants to be up before journald rotates in.
        fileSystems."/var/log".neededForBoot = true;

        # Modern systemd-based initrd: required for the rollback unit below.
        boot.initrd.systemd.enable = true;

        # Roll back `root` and `home` btrfs subvolumes before the real root
        # is mounted: rename the live subvolume into /old_roots/<name>_<ts>
        # for a 30-day inspection window, then create a fresh empty subvol
        # in its place.
        # Loosely based on https://discourse.nixos.org/t/setting-up-impermanence-with-disko-and-luks-with-btrfs-and-also-nuking-everything-on-reboot
        boot.initrd.systemd.services.rollback-root = {
          description = "Roll back root + home btrfs subvolumes to empty";
          wantedBy = [ "initrd.target" ];
          after = [ cfg.rootDeviceUnit ];
          requires = [ cfg.rootDeviceUnit ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            set -euo pipefail

            mkdir -p /btrfs_tmp
            mount -t btrfs -o subvol=/ ${cfg.rootDevice} /btrfs_tmp

            rollback() {
              local target="$1"

              if [[ -e "/btrfs_tmp/$target" ]]; then
                mkdir -p /btrfs_tmp/old_roots
                timestamp=$(date --date="@$(stat -c %Y "/btrfs_tmp/$target")" "+%Y-%m-%d_%H:%M:%S")
                mv "/btrfs_tmp/$target" "/btrfs_tmp/old_roots/''${target}_''${timestamp}"
              fi

              # Garbage-collect saved roots older than 30 days so the disk
              # doesn't silently fill up.
              if [[ -d /btrfs_tmp/old_roots ]]; then
                find /btrfs_tmp/old_roots -maxdepth 1 -mtime +30 | while read -r old; do
                  btrfs subvolume list -o "$old" | cut -f9 -d' ' | while read -r sub; do
                    btrfs subvolume delete "/btrfs_tmp/$sub" || true
                  done
                  btrfs subvolume delete "$old" || true
                done
              fi

              btrfs subvolume create "/btrfs_tmp/$target"
            }

            rollback root
            rollback home

            umount /btrfs_tmp
          '';
        };

        # System-level opt-in state. See the impermanence README for
        # semantics: each entry is bind-mounted from /persist/<path> to
        # <path> on boot.
        environment.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/nixos" # stable UIDs/GIDs across rebuilds
            "/var/lib/systemd" # random-seed, backlight, timers
            "/var/lib/bluetooth"
            "/var/lib/NetworkManager"
            "/var/lib/tailscale"
            "/var/lib/sops-nix"
            "/var/lib/colord"
            "/etc/NetworkManager/system-connections"
          ];
          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
          ];
        };
      };
    };
}
