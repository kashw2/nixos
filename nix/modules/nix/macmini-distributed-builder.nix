{ self, inputs, ... }:
{
  flake.nixosModules.macminiDistributedBuilder =
    { pkgs, lib, ... }:
    {
      nix.buildMachines = [
        {
          hostName = "macmini.local";
          systems = [
            "aarch64-darwin"
          ];
          supportedFeatures = [
            "apple-virt"
            "benchmark"
            "big-parallel"
            "nixos-test"
          ];
          protocol = "ssh-ng";
          sshUser = "keanu";
          sshKey = "/home/keanu/.ssh/id_ed25519";
        }
      ];
    };
}
