{ self, inputs, ... }:
let
  # Hosts that get a per-host installer ISO. Must match the attrs defined in
  # flake.nixosConfigurations (see modules/hosts/*/default.nix).
  hosts = [
    "home"
    "laptop"
    "thinkpad"
    "media"
  ];
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
      # install-host: the single command the user runs after booting the ISO.
      # Searches USB block devices for a keys.txt file (up to depth 3),
      # validates it as an age key, copies it into place, then runs
      # disko-install. After install, drops the key at
      # /mnt/var/lib/sops-nix/key.txt so sops-nix can decrypt on first boot.
      installHost = pkgs.writeShellApplication {
        name = "install-host";
        runtimeInputs = [
          pkgs.util-linux # mount, umount, lsblk
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.age # age-keygen for validation
          inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
        ];
        text = ''
          set -euo pipefail

          # Self-escalate: mount/umount, disko-install, and writing to /mnt
          # all require root. The installer ISO auto-logs in as an
          # unprivileged user, so re-exec under sudo preserving the
          # environment (NIX_PATH etc).
          if [ "$(id -u)" -ne 0 ]; then
            exec sudo -E "$0" "$@"
          fi

          # Offline install: the ISO embeds the target closure and every
          # flake input source tree in /nix/store, so no network is needed
          # for evaluation or build. Tell Nix not to talk to the registry
          # or to substituters, otherwise even with the paths locally
          # present Nix will try to validate them against cache.nixos.org.
          export NIX_CONFIG=$'substituters =\nuse-registries = false\nexperimental-features = nix-command flakes'

          HOST_NAME=${lib.escapeShellArg hostName}
          FLAKE_PATH=/etc/nixos-config
          KEY_DEST=/tmp/sops-key.txt
          MOUNT_POINT=/tmp/keymnt
          WAIT_TIMEOUT=120

          cleanup() {
            if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
              umount "$MOUNT_POINT" || true
            fi
            rm -f "$KEY_DEST"
          }
          trap cleanup EXIT

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
          # The disko config for this host declares the target disk; we
          # surface it here so the user can sanity-check before wiping.
          # ---------------------------------------------------------------
          TARGET_DISK=$(NIXPKGS_ALLOW_UNFREE=1 \
            nix --extra-experimental-features 'nix-command flakes' \
            eval --impure --offline --raw \
            "$FLAKE_PATH#nixosConfigurations.$HOST_NAME.config.disko.devices.disk.main.device")
          echo "Target disk (from disko config): $TARGET_DISK"
          if [ -e "$TARGET_DISK" ]; then
            echo "Disk is present:"
            lsblk -no NAME,SIZE,MODEL,SERIAL "$TARGET_DISK" || true
          else
            echo "WARNING: $TARGET_DISK does not exist on this machine." >&2
            echo "The disko config hardcodes a disk-by-id path that doesn't match." >&2
            echo "You can pass --disk main /dev/XXX to disko-install manually, or edit the host's disko.nix." >&2
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
          # Step 3: Run disko-install. This partitions + formats per the
          # host's disko config, mounts at /mnt, and runs nixos-install.
          # ---------------------------------------------------------------
          echo "Running disko-install..."
          # Pass --disk main explicitly. disko-install internally does
          # `boot.loader.grub.devices = lib.mkVMOverride (lib.attrValues diskMappings)`
          # at priority 10, so without a --disk mapping grub.devices gets
          # forced to [] and the bootloader assertion fails. nixos-anywhere
          # also passes this; matching its behavior here.
          #
          # Intentionally NOT passing --write-efi-boot-entries: the host
          # templates set boot.loader.grub.efiInstallAsRemovable = true
          # (GRUB installs to /EFI/BOOT/BOOTX64.EFI, no NVRAM entry). That
          # flag would set canTouchEfiVariables = true, which conflicts.
          disko-install \
            --flake "$FLAKE_PATH#$HOST_NAME" \
            --disk main "$TARGET_DISK"

          # ---------------------------------------------------------------
          # Step 4: Place the age key on the target so sops-nix can decrypt
          # on first boot. /mnt should still be mounted after disko-install.
          # ---------------------------------------------------------------
          if mountpoint -q /mnt; then
            install -d -m 0755 -o 0 -g 0 /mnt/var/lib/sops-nix
            install -m 0400 -o 0 -g 0 "$KEY_DEST" /mnt/var/lib/sops-nix/key.txt
            echo "Placed sops age key at /mnt/var/lib/sops-nix/key.txt"
            umount -R /mnt
          else
            echo "WARNING: /mnt is not mounted after disko-install; cannot place sops key." >&2
            echo "Mount the target root and copy $KEY_DEST to /var/lib/sops-nix/key.txt (mode 0400) manually before rebooting." >&2
            exit 1
          fi

          echo
          echo "=== Install complete for '$HOST_NAME'. Reboot when ready. ==="
        '';
      };
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      # Embed the flake source at a stable path so disko-install can find
      # the target host config offline.
      environment.etc."nixos-config".source = self;

      environment.systemPackages = [
        pkgs.age
        pkgs.util-linux
        pkgs.parted
        pkgs.cryptsetup
        pkgs.dosfstools
        pkgs.e2fsprogs
        pkgs.btrfs-progs
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
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
        ║  2. Run:   sudo install-host
        ║
        ║  The installer will confirm the target disk before wiping.
        ╚════════════════════════════════════════════════════════════════╝
      '';

      # Identify this ISO clearly in the filename. mkForce overrides the
      # default set by installation-cd-base.nix. (Option was renamed from
      # isoImage.isoBaseName to image.baseName in nixpkgs 25.05+.)
      image.baseName = lib.mkForce "nixos-installer-${hostName}";

      # Ensure the target host's full closure AND the flake's input source
      # trees are embedded in the ISO. The closure lets the installer skip
      # compilation; the input sources let `nix eval` against
      # /etc/nixos-config resolve all inputs without network access.
      system.extraDependencies =
        [
          self.nixosConfigurations.${hostName}.config.system.build.toplevel
        ]
        ++ builtins.filter (p: p != null) (
          map (v: v.outPath or null) (builtins.attrValues (builtins.removeAttrs inputs [ "self" ]))
        );

      # flakes + nix-command are required by disko-install --flake and the
      # key-discovery `nix eval` call in install-host.
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # The host flake currently requires allowUnfree to evaluate (it
      # references terraform among other unfree packages). disko-install
      # invokes `nix build --impure` internally, so exporting this env var
      # in the installer session is sufficient for evaluation to succeed.
      environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
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
