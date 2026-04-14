{ self, inputs, ... }:
{
  flake.nixosModules.jellyfin =
    { pkgs, lib, ... }:
    {

      systemd.services.jellyfin.environment = {
        LIBVA_DRIVER_NAME = "iHD";
        JELLYFIN_WEB_DIR = "${pkgs.jellyfin-web.out}/share/jellyfin-web";
      };

      hardware = {
        enableAllFirmware = true;
        intel-gpu-tools.enable = true;
        graphics = {
          enable = true;
          extraPackages = [
            pkgs.intel-ocl # generic OpenCL support, for all processors
            # For newer processors (Broadwell and higher, ca. 2014), use this paired with `LIBVA_DRIVER_NAME=iHD`:
            pkgs.intel-media-driver
            # In addition, for newer processors (13th gen and higher), add this as well:
            pkgs.intel-compute-runtime
            # In addition once more, for newer processors (11th gen or newer), add this:
            pkgs.vpl-gpu-rt
          ];
        };
      };

      services.jellyfin.enable = true;

      nixpkgs.config.packageOverrides = pkgs: {
        intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      };

    };
}
