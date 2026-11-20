{ self, inputs, ... }:
{

  flake.nixosModules.homeHardwareConfiguration =
    {
      config,
      lib,
      pkgs,
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

      # Windows install on the NVMe. Kept out of disko so a reinstall never
      # touches it. Automounted on first access; nofail keeps boot working if
      # Fast Startup has left the volume dirty.
      fileSystems."/mnt/windows" = {
        device = "/dev/disk/by-uuid/42D2D081D2D07A9D";
        fsType = "ntfs3";
        options = [
          "nofail"
          "x-systemd.automount"
          "uid=1000"
          "umask=022"
          "windows_names"
          "noatime"
        ];
      };

      # ath12k can fail to resume from deep sleep ("failed to resume core: -110"),
      # leaving wlp9s0 dead until reboot. Unload it before suspend and load it
      # fresh on resume.
      powerManagement = {
        powerDownCommands = "${lib.getExe' pkgs.kmod "modprobe"} -r ath12k_wifi7 ath12k";
        resumeCommands = "${lib.getExe' pkgs.kmod "modprobe"} ath12k_wifi7";
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    };

}
