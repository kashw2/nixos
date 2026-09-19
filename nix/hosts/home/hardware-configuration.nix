{ self, inputs, ... }:
{

  flake.nixosModules.homeHardwareConfiguration =
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
            "ahci"
            "xhci_pci"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ "amdgpu" ];
        };
        kernelModules = [ "kvm-amd" ];
      };

      hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
    };

}
