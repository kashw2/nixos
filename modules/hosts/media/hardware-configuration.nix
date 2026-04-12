{ self, inputs, ... }:
{

  flake.nixosModules.mediaHardwareConfiguration =
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
            "xhci_pci"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "sdhci_pci"
            "nvme"
          ];
          kernelModules = [ ];
        };
        kernelParams = [
          "nvme_core.default_ps_max_latency_us=0"
          "pcie_aspm=off"
          "nvme_core.io_timeout=300"
        ];
        kernelModules = [
          "kvm-intel"
          "tcp_bbr"
        ];
      };

      hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
    };

}
