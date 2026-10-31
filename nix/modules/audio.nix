{ self, inputs, ... }:
{
  flake.nixosModules.audio =
    { pkgs, lib, ... }:
    {
      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
      };
    };
}
