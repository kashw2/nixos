{ self, input, ... }:
{
  flake.wrappers.act =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.act;
        flags."-P" = "ubuntu-latest=catthehacker/ubuntu:full-latest";
      };
    };
}
