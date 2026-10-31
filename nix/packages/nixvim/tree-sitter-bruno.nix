{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.tree-sitter-bruno = pkgs.tree-sitter.buildGrammar {
        language = "bruno";
        version = "0-unstable-2025-01-15";
        src = pkgs.fetchFromGitHub {
          owner = "kristoferssolo";
          repo = "tree-sitter-bruno";
          rev = "c6d42e349353f02ad051dd9c88a38df639ef688f";
          hash = "sha256-7XWWAT0PB29TllAo0HWAgGmdflmmtyFscl6XSA12tpU=";
        };
      };
    };
}
