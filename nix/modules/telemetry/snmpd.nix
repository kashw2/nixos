{ ... }:
{
  flake.nixosModules.snmpd =
    { config, ... }:
    {

      services.snmpd = {
        enable = true;
        openFirewall = true;
        configFile = config.sops.templates."snmpd.conf".path;
      };

    };
}
