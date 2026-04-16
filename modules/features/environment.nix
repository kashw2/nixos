{ self, inputs, ... }:
{
  flake.nixosModules.environment =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {

      # Every configuration will import this file so if we import home-manager modules here
      # All configurations and downstream modules will have access to it
      imports = [
        self.nixosModules.nix
        self.nixosModules.telemetry
        self.nixosModules.security
        self.nixosModules.networking
        self.nixosModules.nixvim
        self.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          home-manager.sharedModules = [
            inputs.nixcord.homeModules.nixcord
            inputs.mcp-servers-nix.homeManagerModules.default
          ];
        }
      ];

      options = {
        isServer = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this machine is a headless server. Set to true by serverTemplate.";
        };
        isLaptop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this machine is a laptop. Set to true by laptopTemplate.";
        };
        isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this machine is a desktop. Set to true by desktopTemplate.";
        };
      };

      config = {
        assertions = [
          {
            assertion = config.isServer || config.isLaptop || config.isDesktop;
            message = "A host must declare its type by setting one of isServer, isLaptop, or isDesktop to true. Did you forget to import serverTemplate, laptopTemplate, or desktopTemplate?";
          }
        ];

        # Impermanence wipes / on every boot, so mutable changes to /etc/shadow
        # would not survive. Keanu's password is managed declaratively via
        # sops-nix (users.users.keanu.hashedPasswordFile), so mutable users
        # would be misleading.
        users.mutableUsers = false;

        boot = {
          # All machines run the xanmod kernel
          kernelPackages = pkgs.linuxPackages_xanmod_stable;
          kernel.sysctl = {
            "kernel.sysrq" = 1; # Enable SysRQ for rebooting properly during halts
          };
        };

        environment = {
          shells = [ self.packages.${pkgs.stdenv.hostPlatform.system}.nushell ];
          localBinInPath = true;

          sessionVariables = {
            TERM = "kitty";
            EDITOR = "nvim";
            NIXPKGS_ALLOW_UNFREE = 1;
            NIXPKGS_ALLOW_INSECURE = 1;
          };

          etc."current-system-packages".text =
            let
              packages = map (p: p.name) config.environment.systemPackages;
              sortedUnique = builtins.sort builtins.lessThan (lib.lists.unique packages);
              formatted = lib.strings.concatLines sortedUnique;
            in
            formatted;

          systemPackages = [
            pkgs.nano
            pkgs.openssl
            pkgs.killall
            pkgs.lsof
            pkgs.btop
            pkgs.watch
            pkgs.tree
            pkgs.curl
            pkgs.cliphist
            pkgs.unzip
            pkgs.git
            self.packages.${pkgs.stdenv.hostPlatform.system}.fastfetch
          ];
        };

        time.timeZone = "Australia/Brisbane";
        i18n.defaultLocale = "en_AU.UTF-8";
        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_AU.UTF-8";
          LC_IDENTIFICATION = "en_AU.UTF-8";
          LC_MEASUREMENT = "en_AU.UTF-8";
          LC_MONETARY = "en_AU.UTF-8";
          LC_NAME = "en_AU.UTF-8";
          LC_NUMERIC = "en_AU.UTF-8";
          LC_PAPER = "en_AU.UTF-8";
          LC_TELEPHONE = "en_AU.UTF-8";
          LC_TIME = "en_AU.UTF-8";
        };

        services = {
          fwupd.enable = true;
          gvfs.enable = true; # Nautilus requires this for certain locations (Trash etc)
        };

        system.stateVersion = "25.11";
      };

    };
}
