{ self, inputs, ... }:
{
  flake.nixosModules.storage =
    { config, lib, ... }:
    {
      # Every host is btrfs; scrub catches silent corruption before a read does.
      # The timer is Persistent, so a scrub missed while powered off runs at boot.
      services.btrfs.autoScrub.enable = true;

      # Short self-test nightly at 02:00, long self-test Saturdays at 03:00.
      services.smartd = {
        enable = true;
        defaults.autodetected = "-a -s (S/../.././02|L/../../6/03)";
        # smartd only catches up on tests scheduled while the host was off when
        # it has saved state; it then runs the longest missed test after boot.
        extraOptions = [ "--savestates=/var/lib/smartd/" ];
      };
      systemd.services.smartd.serviceConfig.StateDirectory = "smartd";

      environment.persistence = lib.mkIf config.impermanence.enable {
        "/persist".directories = [ "/var/lib/smartd" ];
      };

      # Guests only get virtio disks, which smartd's DEVICESCAN skips, and smartd
      # exits non-zero when it finds nothing to monitor.
      virtualisation.vmVariant.services.smartd.enable = lib.mkForce false;
      virtualisation.vmVariantWithBootLoader.services.smartd.enable = lib.mkForce false;

      # The VM's root is qemu-vm's ext4 image, not the host's btrfs, and autoScrub
      # asserts that at least one btrfs filesystem is mounted.
      virtualisation.vmVariant.services.btrfs.autoScrub.enable = lib.mkForce false;
      virtualisation.vmVariantWithBootLoader.services.btrfs.autoScrub.enable = lib.mkForce false;
    };
}
