{ self, inputs, ... }:
{

  flake.nixosModules.laptopHardwareConfiguration =
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
            "nvme"
            "usb_storage"
            "xhci_pci"
            "ahci"
            "rtsx_pci_sdmmc"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-intel" ];
      };

      hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
    };

}
