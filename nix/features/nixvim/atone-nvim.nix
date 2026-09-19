{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.atone-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "atone-nvim";
        version = "2025-04-07";
        src = pkgs.fetchFromGitHub {
          owner = "XXiaoA";
          repo = "atone.nvim";
          rev = "44d2a447e1e6db0959d4be18f5a072788a799880";
          hash = "sha256-+nlupLZqrVhb8emYQwbs6mEy7fMhGCa6pXoYGwFBuKY=";
        };
      };
    };
}
