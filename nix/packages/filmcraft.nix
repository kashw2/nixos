{ ... }:
{
  # Starts the desktop app with its loopback control server on 7777, so
  # `filmcraft-cli mcp --bridge 127.0.0.1:7777` can drive the live window. The
  # listener only opens with FILMCRAFT_CONTROL_TOKEN set, which upstream shares
  # through the environment alone, so both binaries load it from a per-session
  # file in $XDG_RUNTIME_DIR, created (0600) by whichever starts first.
  flake.wrappers.filmcraft =
    {
      pkgs,
      lib,
      wlib,
      ...
    }:
    let
      coreutil = lib.getExe' pkgs.coreutils;
    in
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.filmcraft;
        envDefault.FILMCRAFT_CONTROL_PORT = "7777";
        runShell = [
          ''
            token_file="''${XDG_RUNTIME_DIR:?}/filmcraft/control.token"
            if [ ! -s "$token_file" ]; then
              ${coreutil "mkdir"} -p -m 700 "''${token_file%/*}"
              (umask 077 && ${coreutil "od"} -An -N32 -tx1 /dev/urandom | ${coreutil "tr"} -d ' \n' > "$token_file.$$" && ${coreutil "mv"} -n "$token_file.$$" "$token_file"; ${coreutil "rm"} -f "$token_file.$$")
            fi
            export FILMCRAFT_CONTROL_TOKEN="$(< "$token_file")"
          ''
        ];
        # Mirrors the token setup onto the CLI, which the MCP bridge runs.
        wrapperVariants.filmcraft-cli = { };
      };
    };
}
