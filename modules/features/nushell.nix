{ self, inputs, ... }:
{
  flake.wrappers.nushell =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.nushell;
        # Required because we only call them inline in this package's config
        # For the purposes of running a command, not for actually making them available to the PATH
        extraPackages = [
          pkgs.zoxide
          pkgs.starship
          pkgs.carapace
          pkgs.nu_scripts
        ];
        passthru.shellPath = "/bin/nu";
        flags."--config" = pkgs.writeText "config.nu" ''
          let carapace_completer = {|spans|
              ${lib.getExe pkgs.carapace} $spans.0 nushell ...$spans | from json
          }
          $env.config = {
           show_banner: true,
           edit_mode: vi,
           completions: {
           case_sensitive: false # case-sensitive completions
           quick: false    # set to false to prevent auto-selecting completions
           partial: false    # set to false to prevent partial filling of the prompt
           algorithm: "prefix"    # prefix or fuzzy
           external: {
           # set to false to prevent nushell looking into $env.PATH to find more suggestions
               enable: true 
           # set to lower can improve completion performance at the cost of omitting some options
               max_results: 20 
               completer: $carapace_completer # check 'carapace_completer' 
             }
           }
          }

          # Zoxide Configuration
          source ${
            pkgs.runCommand "zoxide-nushell-config.nu" { } ''
              ${lib.getExe pkgs.zoxide} init nushell >> "$out"
            ''
          }

          # Starship Configuration
          use ${
            pkgs.runCommand "starship-nushell-config.nu" { } ''
              ${lib.getExe pkgs.starship} init nu >> "$out"
            ''
          }

          # Carapace Configuration
          source ${
            pkgs.runCommand "carapace-nushell-config.nu" { } ''
              ${lib.getExe pkgs.carapace} _carapace nushell | sed 's|"/homeless-shelter|$"($env.HOME)|g' >> "$out"
            ''
          }

          if ("/run/secrets/infracost_api_key" | path exists) {
            $env.INFRACOST_API_KEY = (open /run/secrets/infracost_api_key | str trim)
          }

          alias ".." = cd ..
          alias "cd" = z
          alias "cls" = ${lib.getExe' pkgs.ncurses "clear"}
          alias "g" = ${lib.getExe pkgs.git}
          alias "lsa" = ${lib.getExe' pkgs.coreutils-full "ls"} --all
          # TODO: Update this to use `config.nix.packages`
          alias "nb" = ${lib.getExe pkgs.nix} build --impure
          alias "nd" = ${lib.getExe pkgs.nix} develop --impure
          alias "nfu" = ${lib.getExe pkgs.nix} flake update
          alias "ns" = ${lib.getExe' pkgs.nix "nix-shell"} -p
          alias "nsp" = ${lib.getExe' pkgs.nix "nix-shell"} --pure
          alias "pgd" = ${lib.getExe' pkgs.postgresql "pg_dump"} -Fc -v -f psql.dump
          alias "pgr" = ${lib.getExe' pkgs.postgresql "pg_restore"} -Fc --no-owner -v
          alias "rbt" = ${lib.getExe' pkgs.systemd "reboot"}
          alias "sdn" = ${lib.getExe' pkgs.systemd "shutdown"} now
          alias "tf" = ${lib.getExe pkgs.terraform}
          alias "tfa" = ${lib.getExe pkgs.terraform} apply
          alias "tfaa" = ${lib.getExe pkgs.terraform} apply --auto-approve
          alias "tfi" = ${lib.getExe pkgs.terraform} init
          alias "tfim" = ${lib.getExe pkgs.terraform} import
          alias "tfiu" = ${lib.getExe pkgs.terraform} init --upgrade
          alias "tfp" = ${lib.getExe pkgs.terraform} plan
          alias "colmena" = ${
            lib.getExe inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
          } --impure

          def nbpr [pr: int, pkg: string] {
            ${lib.getExe pkgs.nix} build $"github:nixos/nixpkgs?ref=pull/($pr)/head#($pkg)" --impure
          }

          def nrpr [pr: int, pkg: string] {
            ${lib.getExe pkgs.nix} run $"github:nixos/nixpkgs?ref=pull/($pr)/head#($pkg)" --impure
          }
        '';
      };
    };
}
