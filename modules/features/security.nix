{ self, inputs, ... }:
{
  flake.nixosModules.security =
    { pkgs, lib, ... }:
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
        auditd.enable = true;
        audit = {
          enable = true;
          rules = [
            "-a exit,always -F arch=b64 -S execve"
            "-a exit,always -F arch=b32 -S execve"
          ];
        };
        sudo.wheelNeedsPassword = false;
        polkit.enable = true;
        rtkit.enable = true;
      };

    };
}
