{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      src = pkgs.fetchFromGitHub {
        owner = "kristoferssolo";
        repo = "tree-sitter-bruno";
        rev = "c6d42e349353f02ad051dd9c88a38df639ef688f";
        hash = "sha256-7XWWAT0PB29TllAo0HWAgGmdflmmtyFscl6XSA12tpU=";
      };

      grammar = pkgs.tree-sitter.buildGrammar {
        language = "bruno";
        version = "0-unstable-2025-01-15";
        inherit src;
      };
    in
    {
      packages.tree-sitter-bruno = grammar;

      packages.bruno-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "bruno-nvim";
        version = "0-unstable-2025-01-15";
        src = pkgs.runCommand "bruno-nvim-src" { } ''
          mkdir -p $out/queries/bruno $out/ftdetect
          cp ${src}/queries/highlights.scm  $out/queries/bruno/highlights.scm
          cp ${src}/queries/indents.scm     $out/queries/bruno/indents.scm
          cp ${src}/queries/injections.scm  $out/queries/bruno/injections.scm
          cp ${src}/queries/folds.scm       $out/queries/bruno/folds.scm
          cat > $out/ftdetect/bruno.vim <<'EOF'
          autocmd BufNewFile,BufRead *.bru setfiletype bruno
          EOF
        '';
      };
    };
}
