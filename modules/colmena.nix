{ self, inputs, ... }:
{
  flake.colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };

      specialArgs = {
        inherit inputs self;
        system = "x86_64-linux";
      };
    };
    home = {
      deployment = {
        targetHost = "home.local";
        targetUser = "keanu";
        tags = [ "linux" ];
      };

      imports = [ self.nixosModules.home ];
    };
    laptop = {
      deployment = {
        targetHost = "laptop.local";
        targetUser = "keanu";
        tags = [ "linux" ];
      };

      imports = [ self.nixosModules.laptop ];
    };
    thinkpad = {
      deployment = {
        targetHost = "thinkpad.local";
        targetUser = "keanu";
        tags = [ "linux" ];
      };

      imports = [ self.nixosModules.thinkpad ];
    };
    media = {
      deployment = {
        targetHost = "media.local";
        targetUser = "keanu";
        tags = [ "linux" ];
      };

      imports = [ self.nixosModules.media ];
    };
  };
}
