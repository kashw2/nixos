{ self, inputs, ... }:
{
  flake.nixosModules.nixvimKeymaps =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.nixvim.keymaps = [
        # Unmap
        {
          # Unmap u because we remap undo to Ctrl + Z
          action = "<Nop>";
          key = "u";
          mode = [ "n" ];
        }
        # General
        {
          action = "g_";
          key = "<C-e>";
          mode = [ "n" ];
        }
        {
          action = "^";
          key = "<C-a>";
          mode = [ "n" ];
        }
        {
          action = ":w<CR>";
          key = "<C-s>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":undo<CR>";
          key = "<C-z>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":redo<CR>";
          key = "<C-S-z>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = "yy";
          key = "<C-c>";
          mode = [ "n" ];
        }
        {
          action = "dd";
          key = "<C-k>";
          mode = [ "n" ];
        }
        {
          action = "gcc";
          key = "<C-/>";
          mode = [
            "n"
            "v"
          ];
          options.remap = true;
        }
        {
          action = ":lua require('fastaction').code_action()<CR>";
          key = "ca";
          mode = [ "n" ];
          options = {
            remap = true;
            silent = true;
          };
        }
        {
          action = ":BlameToggle virtual<CR>";
          key = "gb";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action.__raw = ''
            function()
              local existing = vim.b.lsp_floating_preview
              if existing and vim.api.nvim_win_is_valid(existing) then
                vim.api.nvim_win_close(existing, true)
                vim.b.lsp_floating_preview = nil
                return
              end
              vim.lsp.buf.hover()
            end
          '';
          key = "K";
          mode = [ "n" ];
          options.silent = true;
        }
        # Tabs
        {
          action = ":tabclose<CR>";
          key = "tq";
          mode = [ "n" ];
          options.silent = true;
        }
        # Splits
        {
          action = ":vsplit<CR>";
          key = "sr";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":split<CR>";
          key = "sd";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":q<CR>";
          key = "sq";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":SmartResizeUp<CR>";
          key = "<A-Up>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":SmartResizeRight<CR>";
          key = "<A-Right>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":SmartResizeDown<CR>";
          key = "<A-Down>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":SmartResizeLeft<CR>";
          key = "<A-Left>";
          mode = [ "n" ];
          options.silent = true;
        }
        # Atone
        {
          action = ":Atone toggle<CR>";
          key = "ut";
          mode = [ "n" ];
          options.silent = true;
        }
        # ToggleTerm
        {
          action = ":TermNew direction=float<CR>";
          key = "tn";
          mode = [ "n" ];
          options.silent = true;
        }
        # LazyGit
        {
          action = ":LazyGit<CR>";
          key = "gui";
          mode = [ "n" ];
          options.silent = true;
        }
        # Buffers
        {
          action = ":Bdelete!<CR>";
          key = "bq";
          mode = [ "n" ];
          options.silent = true;
        }
        # Navigation
        {
          action = ":wincmd k<CR>";
          key = "<C-Up>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":wincmd l<CR>";
          key = "<C-Right>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":wincmd j<CR>";
          key = "<C-Down>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":wincmd h<CR>";
          key = "<C-Left>";
          mode = [ "n" ];
          options.silent = true;
        }
        # NvimTree
        {
          action = ":NvimTreeToggle<CR>";
          key = "<C-d>";
          mode = [ "n" ];
          options.silent = true;
        }
        # Telescope
        {
          action = ":Telescope current_buffer_fuzzy_find<CR>";
          key = "<C-f>";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":Telescope live_grep<CR>";
          key = "fg";
          mode = [ "n" ];
          options = {
            remap = true;
            silent = true;
          };
        }
        {
          action = ":Telescope buffers<CR>";
          key = "fb";
          mode = [ "n" ];
          options.silent = true;
        }
        {
          action = ":Telescope find_files<CR>";
          key = "ff";
          mode = [ "n" ];
          options.silent = true;
        }
      ]
      ++ lib.optionals (!config.isServer) [
        # Database
        {
          action = ":DBUIToggle<CR>";
          key = "db";
          mode = [ "n" ];
          options.silent = true;
        }
      ];
    };
}
