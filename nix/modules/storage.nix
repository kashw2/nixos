{ self, inputs, ... }:
{
  flake.nixosModules.storage =
    { ... }:
    {
      # Every host is btrfs; scrub catches silent corruption before a read does.
      services.btrfs.autoScrub.enable = true;
    };
}
