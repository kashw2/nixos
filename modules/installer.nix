{
  self,
  inputs,
  lib,
  ...
}:
let
  hosts = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));
in
{
  flake.nixosModules.installer =
    {
      config,
      pkgs,
      lib,
      hostName,
      ...
    }:
    let
      # Pre-built artifacts from the target host's NixOS configuration.
      # These are evaluated at ISO build time, eliminating all flake
      # evaluation (and thus network access) at install time.
      targetConfig = self.nixosConfigurations.${hostName}.config;
      diskoScript = targetConfig.system.build.diskoScript;
      systemToplevel = targetConfig.system.build.toplevel;
      targetDisk = targetConfig.disko.devices.disk.main.device;

      # install-host: the single command the user runs after booting the ISO.
      # Searches USB block devices for a keys.txt file (up to depth 3),
      # validates it as an age key, then partitions + formats the target
      # disk, injects the key, and runs nixos-install with the pre-built
      # system closure — all without any network access.
      installHost = pkgs.writeShellApplication {
        name = "install-host";
        runtimeInputs = [
          pkgs.util-linux # mount, umount, lsblk
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.age # age-keygen for validation
        ];
        text = ''
          set -euo pipefail

          # Self-escalate: mount/umount, disko, and writing to /mnt all
          # require root. The installer ISO auto-logs in as an unprivileged
          # user, so re-exec under sudo preserving the environment.
          if [ "$(id -u)" -ne 0 ]; then
            exec sudo -E "$0" "$@"
          fi

          HOST_NAME=${lib.escapeShellArg hostName}
          TARGET_DISK=${lib.escapeShellArg targetDisk}
          KEY_DEST=/tmp/sops-key.txt
          SSH_KEY_DIR=/tmp/ssh-host-keys
          MOUNT_POINT=/tmp/keymnt
          WAIT_TIMEOUT=120

          cleanup() {
            if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
              umount "$MOUNT_POINT" || true
            fi
            rm -f "$KEY_DEST"
            rm -rf "$SSH_KEY_DIR"
          }
          trap cleanup EXIT

          mkdir -p "$SSH_KEY_DIR"

          mkdir -p "$MOUNT_POINT"

          echo "=== NixOS installer for host: $HOST_NAME ==="
          echo

          # ---------------------------------------------------------------
          # Step 1: Find the sops age key on a USB device.
          # Scans /dev/disk/by-id/usb-* (which only exists for USB-attached
          # block devices — naturally excludes the target disk and the
          # installer USB's internal layout is fine to scan too, we just
          # won't find keys.txt there). Polls for up to WAIT_TIMEOUT seconds
          # so the user can plug in the key USB after starting the installer.
          # ---------------------------------------------------------------
          echo "Looking for keys.txt on a USB device (recursive, max depth 3)..."
          echo "Plug in your sops key USB now if you haven't already."
          echo

          find_key() {
            local candidates=()
            # Prefer partitions; fall back to whole-disk devices (USB sticks
            # sometimes have a filesystem without a partition table).
            shopt -s nullglob
            for dev in /dev/disk/by-id/usb-*-part* /dev/disk/by-id/usb-*; do
              # Skip symlink targets we've already seen (e.g. /dev/disk/by-id/usb-Foo
              # and /dev/disk/by-id/usb-Foo-0:0 often resolve to the same device).
              local real
              real=$(readlink -f "$dev")
              local seen=0
              for c in "''${candidates[@]}"; do
                if [ "$c" = "$real" ]; then seen=1; break; fi
              done
              if [ "$seen" -eq 0 ]; then
                candidates+=("$real")
              fi
            done
            shopt -u nullglob

            for dev in "''${candidates[@]}"; do
              # Try to mount read-only, suppress noise. Many candidates will
              # fail (whole-disk device when partitions exist, unknown FS).
              if ! mount -o ro,nosuid,nodev,noexec "$dev" "$MOUNT_POINT" 2>/dev/null; then
                continue
              fi

              # Recursive search, bounded depth.
              while IFS= read -r keyfile; do
                if age-keygen -y "$keyfile" >/dev/null 2>&1; then
                  echo "Found valid age key at: $dev:$(realpath --relative-to="$MOUNT_POINT" "$keyfile")"
                  cp "$keyfile" "$KEY_DEST"
                  chmod 0400 "$KEY_DEST"

                  # Also grab SSH host keys from sops/<hostname>/ if present.
                  local ssh_src="$MOUNT_POINT/sops/$HOST_NAME"
                  if [ -d "$ssh_src" ]; then
                    for keyname in ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
                      if [ -f "$ssh_src/$keyname" ]; then
                        cp "$ssh_src/$keyname" "$SSH_KEY_DIR/$keyname"
                        chmod 0600 "$SSH_KEY_DIR/$keyname"
                        echo "Found SSH host key: sops/$HOST_NAME/$keyname"
                      fi
                    done
                  fi

                  umount "$MOUNT_POINT"
                  return 0
                fi
              done < <(find "$MOUNT_POINT" -maxdepth 3 -type f -name keys.txt 2>/dev/null)

              umount "$MOUNT_POINT"
            done
            return 1
          }

          deadline=$(( $(date +%s) + WAIT_TIMEOUT ))
          while true; do
            if find_key; then
              break
            fi
            if [ "$(date +%s)" -ge "$deadline" ]; then
              echo "ERROR: No valid keys.txt found on any USB device within ''${WAIT_TIMEOUT}s." >&2
              echo "Ensure the USB is plugged in and contains a keys.txt (within 3 directory levels) that is a valid age key." >&2
              exit 1
            fi
            sleep 2
          done
          echo

          # ---------------------------------------------------------------
          # Step 2: Show the target disk and ask for confirmation.
          # The target disk path is baked in from the host's disko config
          # at ISO build time.
          # ---------------------------------------------------------------
          echo "Target disk (from disko config): $TARGET_DISK"
          if [ -e "$TARGET_DISK" ]; then
            echo "Disk is present:"
            lsblk -no NAME,SIZE,MODEL,SERIAL "$TARGET_DISK" || true
          else
            echo "WARNING: $TARGET_DISK does not exist on this machine." >&2
            echo "The disko config hardcodes a disk-by-id path that doesn't match." >&2
            echo "Rebuild the ISO with the correct device in the host's disko.nix." >&2
          fi
          echo
          echo "THIS WILL ERASE THE DISK ABOVE."
          printf "Type 'yes' to proceed: "
          read -r CONFIRM
          if [ "$CONFIRM" != "yes" ]; then
            echo "Aborted."
            exit 1
          fi

          # ---------------------------------------------------------------
          # Step 3: Partition, format, mount, inject secrets, and install.
          # Uses the pre-built disko script and system closure — no flake
          # evaluation or network access required.
          # ---------------------------------------------------------------
          echo "Partitioning and formatting..."
          DISKO_SKIP_SWAP=1 ${diskoScript}

          echo "Injecting secrets into target filesystem..."
          # Write to /mnt/persist/... — /mnt/var and /mnt/etc live on the
          # `root` btrfs subvolume, which the rollback-root initrd service
          # wipes on first boot. Impermanence then bind-mounts these paths
          # from /persist at runtime (see modules/features/impermanence.nix
          # and modules/features/sops.nix).
          mkdir -p /mnt/persist/var/lib/sops-nix
          cp "$KEY_DEST" /mnt/persist/var/lib/sops-nix/key.txt
          chmod 0400 /mnt/persist/var/lib/sops-nix/key.txt

          for keyname in ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
            if [ -f "$SSH_KEY_DIR/$keyname" ]; then
              mkdir -p /mnt/persist/etc/ssh
              cp "$SSH_KEY_DIR/$keyname" "/mnt/persist/etc/ssh/$keyname"
              chmod 0600 "/mnt/persist/etc/ssh/$keyname"
              echo "Installed SSH host key: $keyname"
            fi
          done

          echo "Installing NixOS (copying store closure + bootloader)..."
          NIX_CONFIG=$'substituters =' \
            ${config.system.build.nixos-install}/bin/nixos-install \
              --system ${systemToplevel} \
              --root /mnt \
              --no-channel-copy \
              --no-root-password

          echo
          echo "=== Install complete for '$HOST_NAME'. Reboot when ready. ==="
        '';
      };
    in
    {
      environment.systemPackages = [
        pkgs.age
        pkgs.util-linux
        pkgs.parted
        pkgs.cryptsetup
        pkgs.dosfstools
        pkgs.e2fsprogs
        pkgs.btrfs-progs
        installHost
      ];

      # install-iso already auto-logins root on tty1; add a clear banner so
      # the user knows the one command to run.
      users.motd = ''

        ╔════════════════════════════════════════════════════════════════╗
        ║  NixOS auto-installer for host: ${hostName}
        ║
        ║  1. Plug in a USB containing your sops age key as 'keys.txt'
        ║     (anywhere within 3 directory levels of the filesystem root).
        ║     Optional: place SSH host keys under sops/${hostName}/
        ║     (ssh_host_ed25519_key + .pub).
        ║  2. Run:   sudo install-host
        ║
        ║  The installer will confirm the target disk before wiping.
        ╚════════════════════════════════════════════════════════════════╝
      '';

      # Identify this ISO clearly in the filename. mkForce overrides the
      # default set by installation-cd-base.nix. (Option was renamed from
      # isoImage.isoBaseName to image.baseName in nixpkgs 25.05+.)
      image.baseName = lib.mkForce "nixos-installer-${hostName}";

      # Embed the target host's full system closure and disko script in
      # the ISO so the installer can run fully offline. The system closure
      # transitively includes every store path the installed system needs;
      # the disko script bundles its own tool dependencies (parted, mkfs,
      # btrfs-progs, etc.) which are NOT part of the target system closure.
      system.extraDependencies = [
        systemToplevel
        diskoScript
      ];
    };

  # Expose one installer ISO package per host as
  # `packages.<system>.installer-<hostName>`. Build with e.g.:
  #   nix build .#installer-thinkpad
  perSystem =
    { system, ... }:
    {
      packages = builtins.listToAttrs (
        map (hostName: {
          name = "installer-${hostName}";
          value = inputs.nixos-generators.nixosGenerate {
            inherit system;
            format = "install-iso";
            specialArgs = {
              inherit self inputs hostName;
            };
            modules = [
              self.nixosModules.installer
            ];
          };
        }) hosts
      );
    };
}
