{ self, inputs, ... }:
{
  flake.nixosModules.buildboxDistributedBuilder =
    { pkgs, lib, ... }:
    {
      nix.buildMachines = [
        {
          hostName = "aarch64-build-box.nix-community.org";
          systems = [ "aarch64-linux" ];
          supportedFeatures = [
            "kvm"
            "nixos-test"
            "big-parallel"
            "benchmark"
          ];
          protocol = "ssh-ng";
          sshUser = "kashw2";
          sshKey = "/home/keanu/.ssh/id_ed25519";
        }
        {
          hostName = "darwin-build-box.nix-community.org";
          systems = [ "x86_64-darwin" ];
          supportedFeatures = [
            "apple-virt"
            "benchmark"
            "big-parallel"
            "nixos-test"
          ];
          protocol = "ssh-ng";
          sshUser = "kashw2";
          sshKey = "/home/keanu/.ssh/id_ed25519";
        }
      ];
    };
}
