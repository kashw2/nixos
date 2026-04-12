{ self, inputs, ... }:
{
  flake.nixosModules.nixvimKeymaps =
    { pkgs, lib, ... }:
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
        }
        {
          action = ":undo<CR>";
          key = "<C-z>";
          mode = [ "n" ];
        }
        {
          action = ":redo<CR>";
          key = "<C-S-z>";
          mode = [ "n" ];
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
          options.remap = true;
        }
        {
          action = ":BlameToggle virtual<CR>";
          key = "gb";
          mode = [ "n" ];
        }
        # Tabs
        {
          action = ":tabclose";
          key = "tq";
          mode = [ "n" ];
        }
        # Splits
        {
          action = ":vsplit<CR>";
          key = "sr";
          mode = [ "n" ];
        }
        {
          action = ":split<CR>";
          key = "sd";
          mode = [ "n" ];
        }
        {
          action = ":q<CR>";
          key = "sq";
          mode = [ "n" ];
        }
        {
          action = ":SmartResizeUp<CR>";
          key = "<A-Up>";
          mode = [ "n" ];
        }
        {
          action = ":SmartResizeRight<CR>";
          key = "<A-Right>";
          mode = [ "n" ];
        }
        {
          action = ":SmartResizeDown<CR>";
          key = "<A-Down>";
          mode = [ "n" ];
        }
        {
          action = ":SmartResizeLeft<CR>";
          key = "<A-Left>";
          mode = [ "n" ];
        }
        # Atone
        {
          action = ":Atone toggle<CR>";
          key = "ut";
          mode = [ "n" ];
        }
        # ToggleTerm
        {
          action = ":TermNew direction=float<CR>";
          key = "tn";
          mode = [ "n" ];
        }
        # LazyGit
        {
          action = ":LazyGit<CR>";
          key = "gui";
          mode = [ "n" ];
        }
        # Buffers
        {
          action = ":Bdelete!<CR>";
          key = "bq";
          mode = [ "n" ];
        }
        # Navigation
        {
          action = ":wincmd k<CR>";
          key = "<C-Up>";
          mode = [ "n" ];
        }
        {
          action = ":wincmd l<CR>";
          key = "<C-Right>";
          mode = [ "n" ];
        }
        {
          action = ":wincmd j<CR>";
          key = "<C-Down>";
          mode = [ "n" ];
        }
        {
          action = ":wincmd h<CR>";
          key = "<C-Left>";
          mode = [ "n" ];
        }
        # NvimTree
        {
          action = ":NvimTreeToggle<CR>";
          key = "<C-d>";
          mode = [ "n" ];
        }
        # Telescope
        {
          action = ":Telescope current_buffer_fuzzy_find<CR>";
          key = "<C-f>";
          mode = [ "n" ];
        }
        {
          action = ":Telescope live_grep<CR>";
          key = "fg";
          mode = [ "n" ];
          options.remap = true;
        }
        {
          action = ":Telescope buffers<CR>";
          key = "fb";
          mode = [ "n" ];
        }
        {
          action = ":Telescope find_files<CR>";
          key = "ff";
          mode = [ "n" ];
        }
        {
          action = ":DBUIToggle<CR>";
          key = "db";
          mode = [ "n" ];
        }
      ];
    };
}
