{ self, inputs, ... }:
{

  flake.nixosModules.homelabHardwareConfiguration =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "ahci"
            "xhci_pci"
            "ata_generic"
            "ehci_pci"
            "usbhid"
            "sd_mod"
            "sr_mod"
            "rtsx_usb_sdmmc"
          ];
          kernelModules = [ ];
        };
        kernelParams = [ ];
        kernelModules = [
          "kvm-intel"
        ];
      };

      hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
    };

}
