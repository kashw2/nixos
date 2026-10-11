{ self, inputs, ... }:
{
  flake.nixosModules.boot =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkMerge [
        {
          boot = {
            # All machines run the xanmod kernel
            kernelPackages = pkgs.linuxPackages_xanmod_stable;
            kernel.sysctl = {
              "kernel.sysrq" = 1; # Enable SysRQ for rebooting properly during halts
            };
          };
        }
      ];
    };
}
