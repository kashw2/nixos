{ self, inputs, ... }:
{
  flake.nixosModules.security =
    { config, ... }:
    {

      services = {
        fail2ban = {
          enable = true;
          maxretry = 5;
          bantime = "1h";
          bantime-increment = {
            enable = true;
            multipliers = "1 2 4 8 16 24";
            maxtime = "24h";
            overalljails = true;
          };
        };
      };

      security = {
        sudo.wheelNeedsPassword = false;
        polkit.enable = true;
        rtkit.enable = !config.isServer;

        auditd = {
          enable = true;
          settings = {
            log_file = "/var/log/audit/audit.log";
            log_format = "ENRICHED";
          };
        };
        audit = {
          enable = true;
          backlogLimit = 16384;
          rules = [
            "-a always,exclude -F msgtype=PATH"
            "-a always,exclude -F msgtype=CWD"
            "-a always,exclude -F msgtype=BPF"
            "-a exit,always -F arch=b64 -S execve -F auid>=1000 -F auid!=unset -k commands"
            "-a exit,always -F arch=b32 -S execve -F auid>=1000 -F auid!=unset -k commands"
          ];
        };
      };

    };
}
