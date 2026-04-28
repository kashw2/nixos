{ self, inputs, ... }:
{
  flake.nixosModules.security =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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
        rtkit.enable = true;

        apparmor = {
          enable = true;
          killUnconfinedConfinables = true;
          packages = [ pkgs.apparmor-profiles ];
          # Profiles ship in `complain` so denials log without blocking; flip
          # individual entries to `enforce` after a clean run under load.
          policies = {
            "nginx" = lib.mkIf config.services.nginx.enable {
              state = "complain";
              profile = ''
                include <tunables/global>

                profile nginx ${config.services.nginx.package}/bin/nginx {
                  include <abstractions/base>
                  include <abstractions/nameservice>
                  include <abstractions/openssl>
                  include "${pkgs.apparmorRulesFromClosure { name = "nginx"; } config.services.nginx.package}"

                  capability net_bind_service,
                  capability setuid,
                  capability setgid,
                  capability dac_override,
                  capability dac_read_search,
                  capability chown,

                  network inet stream,
                  network inet6 stream,
                  network inet dgram,
                  network inet6 dgram,

                  ${config.services.nginx.package}/bin/nginx mr,

                  /etc/nginx/** r,
                  /etc/ssl/certs/** r,
                  /var/log/nginx/** rw,
                  /var/spool/nginx/** rwk,
                  /run/nginx/*.pid rw,
                  /run/nginx.pid rw,
                  /run/nginx/** rw,
                  /proc/sys/kernel/random/uuid r,
                  @{PROC}/@{pid}/** r,

                  deny /home/** rwx,
                  deny /root/** rwx,
                }
              '';
            };

            "jellyfin" = lib.mkIf config.services.jellyfin.enable {
              state = "complain";
              profile = ''
                include <tunables/global>

                profile jellyfin ${config.services.jellyfin.package}/bin/jellyfin {
                  include <abstractions/base>
                  include <abstractions/nameservice>
                  include <abstractions/ssl_certs>
                  include <abstractions/audio>
                  include "${pkgs.apparmorRulesFromClosure { name = "jellyfin"; } config.services.jellyfin.package}"

                  network inet stream,
                  network inet6 stream,
                  network inet dgram,
                  network inet6 dgram,
                  network netlink raw,

                  ${config.services.jellyfin.package}/bin/jellyfin mrix,

                  /var/lib/jellyfin/** rwk,
                  /var/cache/jellyfin/** rwk,
                  /var/log/jellyfin/** rw,
                  /mnt/torrents/** r,
                  /tmp/** rwk,
                  /proc/sys/kernel/random/uuid r,
                  /sys/devices/system/cpu/** r,
                  @{PROC}/@{pid}/** r,
                  @{PROC}/sys/net/core/somaxconn r,

                  deny /home/** rwx,
                  deny /root/** rwx,
                }
              '';
            };
          };
        };
      };

    };
}
