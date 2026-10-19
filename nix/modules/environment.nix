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
        self.nixosModules.boot
        self.nixosModules.nix
        self.nixosModules.telemetry
        self.nixosModules.oneuptime
        self.nixosModules.security
        self.nixosModules.networking
        self.nixosModules.nixvim
        self.nixosModules.sops
        self.nixosModules.qemu
        self.nixosModules.storage
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

        documentation.enable = false;

        programs.nix-ld = lib.mkIf (!config.isServer) {
          enable = true;
          libraries = [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.icu
            pkgs.openssl
          ];
        };

        environment = {
          shells = [ self.packages.${pkgs.stdenv.hostPlatform.system}.nushell ];
          localBinInPath = true;

          sessionVariables = {
            TERM = "kitty";
            EDITOR = "nvim";
            NIXPKGS_ALLOW_UNFREE = 1;
            NIXPKGS_ALLOW_INSECURE = 1;
          }
          // lib.optionalAttrs (!config.isServer) {
            NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
          };

          pathsToLink = lib.optionals (!config.isServer) [
            "/share/nautilus-python/extensions"
          ];

          etc."current-system-packages".text =
            let
              packages = map (p: p.name) config.environment.systemPackages;
              sortedUnique = builtins.sort builtins.lessThan (lib.lists.unique packages);
              formatted = lib.strings.concatLines sortedUnique;
            in
            formatted;

          systemPackages = [
            pkgs.openssl
            pkgs.killall
            pkgs.lsof
            pkgs.btop
            pkgs.tree
            self.packages.${pkgs.stdenv.hostPlatform.system}.fastfetch
          ]
          ++ lib.optionals (!config.isServer) [
            pkgs.curl
            pkgs.watch
            pkgs.cliphist
            pkgs.git
            pkgs.unzip
            pkgs.nautilus-python
            inputs.nautilus-my-computer.packages.${pkgs.stdenv.hostPlatform.system}.default
            inputs.loaf-fm.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        };

        time.timeZone = "Australia/Melbourne";
        i18n.defaultLocale = "en_AU.UTF-8";
        i18n.supportedLocales = [ "en_AU.UTF-8/UTF-8" ];
        services = {
          fwupd.enable = !config.isServer;
        };

        system.stateVersion = "25.11";
      };

    };
}
