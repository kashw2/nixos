{ self, inputs, ... }:
{
  flake.nixosModules.nixvim =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nixvim.nixosModules.nixvim
        self.nixosModules.nixvimPlugins
        self.nixosModules.nixvimColorschemes
        self.nixosModules.nixvimLsp
        self.nixosModules.nixvimKeymaps
        self.nixosModules.nixvimHighlights
      ];

      programs.nixvim = {
        enable = true;
        nixpkgs.source = inputs.nixpkgs;
        nixpkgs.config.allowUnfree = true;
        package =
          (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim).overrideAttrs
            (_: {
              doCheck = false;
              doInstallCheck = false;
            });
        viAlias = true;
        vimAlias = true;
        globalOpts = {
          wrap = false;
          number = true;
          relativenumber = true;
          shortmess = "filnxtToOFTSI";
          more = false;
          scrolloff = 8;
        };
        diagnostic.settings = {
          virtual_lines = false;
          virtual_text = true;
        };
        autoCmd = [
          {
            desc = "Terraform New File LSP Fix";
            event = [
              "BufEnter"
              "BufRead"
              "BufNewFile"
            ];
            pattern = [
              "*.tf"
              "*.tfvars"
            ];
            command = "set filetype=terraform";
          }
          {
            desc = "Auto-answer swap-file prompts";
            event = [ "SwapExists" ];
            pattern = [ "*" ];
            command = "let v:swapchoice = 'e'";
          }
        ];
        extraPackages = [
          pkgs.shfmt
          inputs.nixfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        ++ lib.optionals (!config.isServer) [
          pkgs.ueberzugpp
          pkgs.yq-go
          pkgs.postgresql # Used so that the database plugin can use the psql executable
          pkgs.ansible-language-server
        ];
      };
    };
}
