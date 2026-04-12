{ self, inputs, ... }:
{
  flake.nixosModules.nixvimHighlights =
    { pkgs, lib, ... }:
    {
      programs.nixvim.highlightOverride = {
        NvimTreeNormal = {
          bg = "#07070E";
          fg = "#ffffff";
        };
        NvimTreeNormalNC = {
          bg = "#07070E";
          fg = "#ffffff";
        };
        NvimTreeOpenedFolderName = {
          fg = "#D0D7A0";
        };
        NvimTreeRootFolder = {
          fg = "#AEB4C0";
        };
        NvimTreeFolderName = {
          fg = "#D0D7A0";
        };
        NvimTreeGitDirty = {
          fg = "#D9B76A";
        };
        NvimTreeGitNew = {
          fg = "#8FCF7A";
        };
        NvimTreeGitDeleted = {
          fg = "#D97A8A";
        };
        NvimTreeGitStaged = {
          fg = "#6AB7D9";
        };
        NvimTreeGitMerge = {
          fg = "#A892D9";
        };
        NvimTreeGitRenamed = {
          fg = "#D98F64";
        };
        NvimTreeFolderIcon = {
          fg = "#C8D27A";
        };
        NvimTreeOpenedFolderIcon = {
          fg = "#C8D27A";
        };
        NvimTreeSymlinkFolderIcon = {
          fg = "#C8D27A";
        };
        NvimTreeWinSeparator = {
          fg = "#72768D";
        };
        WinSeparator = {
          fg = "#72768D";
        };
      };
    };
}
