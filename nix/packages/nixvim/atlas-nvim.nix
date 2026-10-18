{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.atlas-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "atlas-nvim";
        version = "2026-10-16";
        src = pkgs.fetchFromGitHub {
          owner = "emrearmagan";
          repo = "atlas.nvim";
          rev = "51bd64e0821afeb957b43cf4c30fd9c10033b634";
          hash = "sha256-IcHv/A+daZWXCcVbkvEztmTuPNJjSz9H7VJAscVjMbg=";
        };
        # Optional integrations; their deps are only loaded when configured.
        nvimSkipModules = [
          "atlas.pulls.diff.codediff.annotations"
          "atlas.pulls.diff.codediff.init"
          "atlas.pulls.diff.codediff.keymaps"
          "atlas.pulls.diff.diffview.init"
          "atlas.pulls.diff.diffview.keymaps"
          "atlas.ui.picker.fzf_lua"
          "atlas.ui.picker.snacks"
        ];
      };
    };
}
