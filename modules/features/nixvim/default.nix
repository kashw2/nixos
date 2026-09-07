{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    nixvimModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
  };

  config.flake.nixvimModules.default =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        self.nixvimModules.host
        self.nixvimModules.plugins
        self.nixvimModules.colorschemes
        self.nixvimModules.lsp
        self.nixvimModules.keymaps
        self.nixvimModules.highlights
      ];

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
        cursorline = true;
        shortmess = "filnxtToOFTSI";
        more = false;
        scrolloff = 14;
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        undofile = true;
        autoread = true;
        clipboard = "unnamedplus";
        ignorecase = true;
        smartcase = true;
        signcolumn = "yes";
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
        {
          desc = "Check for external file changes on focus and idle";
          event = [
            "FocusGained"
            "BufEnter"
            "CursorHold"
            "CursorHoldI"
          ];
          pattern = [ "*" ];
          command = "if mode() !~ '\\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif";
        }
      ];
      extraPackages = lib.optionals (!config.host.isServer) [
        pkgs.ueberzugpp
        pkgs.ansible-language-server
      ];
    };

  config.flake.nixosModules.nixvim =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [ inputs.nixvim.nixosModules.nixvim ];

      programs.nixvim = {
        imports = [ self.nixvimModules.default ];

        host = {
          isServer = config.isServer;
          codestatsSetup = config.sops.templates."codestats-setup.lua".path;
          claudeCommand =
            let
              hmClaude = config.home-manager.users.keanu.programs.claude-code;
            in
            if hmClaude.enable then lib.getExe hmClaude.finalPackage else lib.getExe pkgs.claude-code;
        };

        enable = true;
        nixpkgs.source = inputs.nixpkgs;
        nixpkgs.config.allowUnfree = true;
      };
    };
}
