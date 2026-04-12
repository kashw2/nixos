{ self, inputs, ... }:
{
  flake.nixosModules.audio =
    { pkgs, lib, ... }:
    {
      xdg.sounds.enable = true;

      services.pipewire = {
        enable = true;
        audio.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
        alsa.enable = true;
      };
    };
}
