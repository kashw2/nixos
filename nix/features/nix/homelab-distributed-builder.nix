{ self, inputs, ... }:
{
  flake.nixosModules.homelabDistributedBuilder =
    { pkgs, lib, ... }:
    {
      nix.buildMachines = [
        {
          hostName = "homelab.local";
          systems = [ "x86_64-linux" ];
          maxJobs = 16;
          supportedFeatures = [
            "kvm"
            "nixos-test"
            "big-parallel"
            "benchmark"
          ];
          protocol = "ssh-ng";
          sshUser = "keanu";
          sshKey = "/home/keanu/.ssh/id_ed25519";
        }
      ];
    };
}
