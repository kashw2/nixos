{
  description = "Keanu Ashwell's Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nix.url = "github:nixos/nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena.url = "github:zhaofengli/colmena";
    wrapper-modules.url = "github:birdeehub/nix-wrapper-modules";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprpaper.url = "github:hyprwm/hyprpaper";
    hypridle.url = "github:hyprwm/hypridle";
    nixvim.url = "github:nix-community/nixvim";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic.url = "github:zhaofengli/attic";
    nixcord.url = "github:4evy/nixcord";
    nixos-generators.url = "github:nix-community/nixos-generators";
    impermanence.url = "github:nix-community/impermanence";
    quickshell.url = "github:quickshell-mirror/quickshell";
    nixfmt.url = "github:nixos/nixfmt";
    nixd.url = "github:nix-community/nixd";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nautilus-my-computer.url = "github:yannmasoch/nautilus-my-computer?dir=packaging/nix";
    tuicr.url = "github:agavra/tuicr";
    workmux.url = "github:raine/workmux";
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    i-have-adhd = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        systems = [ "x86_64-linux" ];
        imports =
          (inputs.import-tree [
            ./modules
            ./tests
          ]).imports
          ++ [
            inputs.wrapper-modules.flakeModules.default
          ];
      };
}
