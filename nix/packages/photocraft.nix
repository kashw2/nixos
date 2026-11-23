{ ... }:
{
  # Control server on 7878 for `photocraft-cli mcp --bridge`.
  flake.wrappers.photocraft =
    {
      pkgs,
      lib,
      wlib,
      ...
    }:
    let
      runtime = data: {
        inherit data;
        esc-fn = wlib.escapeShellArgWithEnv;
      };
      root = "$HOME/Documents/Artcraft/photocraft";
      tokenFile = "$HOME/.local/state/photocraft/control.token";
    in
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.photocraft;
        envDefault = {
          PHOTOCRAFT_CONTROL_PORT = "7878";
          PHOTOCRAFT_CONTROL_TOKEN_FILE = runtime tokenFile;
          PHOTOCRAFT_AUTOMATION_READ_ROOT = runtime root;
          PHOTOCRAFT_AUTOMATION_WRITE_ROOT = runtime root;
        };
        # App needs the root, bridge the token (which the app reuses).
        runShell = [
          ''
            ${lib.getExe' pkgs.coreutils "mkdir"} -p "${root}"
            token_file="${tokenFile}"
            if [ ! -s "$token_file" ]; then
              ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 700 "''${token_file%/*}"
              (umask 077 && ${lib.getExe' pkgs.coreutils "od"} -An -N32 -tx1 /dev/urandom | ${lib.getExe' pkgs.coreutils "tr"} -d ' \n' > "$token_file.$$" && ${lib.getExe' pkgs.coreutils "mv"} -n "$token_file.$$" "$token_file"; ${lib.getExe' pkgs.coreutils "rm"} -f "$token_file.$$")
            fi
          ''
        ];
        # No env: PHOTOCRAFT_CONTROL_PORT would make a bare `photocraft-cli mcp` bridge.
        wrapperVariants.photocraft-cli.envDefault = { };
      };
    };
}
