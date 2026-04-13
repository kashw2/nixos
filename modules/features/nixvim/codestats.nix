{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.codestats = pkgs.vimUtils.buildVimPlugin {
        name = "codestats";
        src = pkgs.fetchFromGitHub {
          owner = "liljaylj";
          repo = "codestats.nvim";
          rev = "041b315c4f82997186fcdb3fc2f687cc128a28f3";
          hash = "sha256-00yy4Ftk5LLxoWJwjggJcJvkQLkvGhOuXxgyBGi9Pig=";
        };
        dependencies = [ pkgs.vimPlugins.plenary-nvim ];
      };
    };
}
