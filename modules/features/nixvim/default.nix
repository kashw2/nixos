{ self, inputs, ... }:
{
  flake.nixosModules.nixvim =
    { pkgs, lib, ... }:
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
        package = pkgs.neovim-unwrapped;
        viAlias = true;
        vimAlias = true;
        globalOpts = {
          wrap = false;
          number = true;
          relativenumber = true;
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
        ];
        extraPackages = [
          pkgs.shfmt
          pkgs.yq-go
          pkgs.nixfmt
          pkgs.postgresql # Used so that the database plugin can use the psql executable
        ];
      };
    };
}
