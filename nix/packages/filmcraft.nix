{ ... }:
{
  # Control server on 7777 for `filmcraft-cli mcp --bridge`. It needs
  # FILMCRAFT_CONTROL_TOKEN, so app and CLI share a per-session token file.
  flake.wrappers.filmcraft =
    {
      pkgs,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.filmcraft;
        envDefault.FILMCRAFT_CONTROL_PORT = "7777";
        runShell = [
          ''
            token_file="''${XDG_RUNTIME_DIR:?}/filmcraft/control.token"
            if [ ! -s "$token_file" ]; then
              ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 700 "''${token_file%/*}"
              (umask 077 && ${lib.getExe' pkgs.coreutils "od"} -An -N32 -tx1 /dev/urandom | ${lib.getExe' pkgs.coreutils "tr"} -d ' \n' > "$token_file.$$" && ${lib.getExe' pkgs.coreutils "mv"} -n "$token_file.$$" "$token_file"; ${lib.getExe' pkgs.coreutils "rm"} -f "$token_file.$$")
            fi
            export FILMCRAFT_CONTROL_TOKEN="$(< "$token_file")"
          ''
        ];
        wrapperVariants.filmcraft-cli = { };
      };
    };
}
