{ self, inputs, ... }:
{
  flake.nixosModules.networking =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.openssh.enable = true;

      services.tailscale = {
        enable = true;
        openFirewall = true;
        extraSetFlags = [
          "--accept-dns=false"
        ];
        authKeyFile = config.sops.secrets."tailscale".path;
      };

      services.iperf3.enable = true;

      networking = {
        hosts = {
          "100.77.4.43" = [ "home.tailscale" ];
          "100.65.188.7" = [ "family.tailscale" ];
          "100.92.159.22" = [ "homelab.tailscale" ];
          "100.79.68.16" = [ "laptop.tailscale" ];
          "100.114.180.17" = [ "thinkpad.tailscale" ];
          "100.91.81.100" = [ "macmini.tailscale" ];
          "100.116.38.8" = [ "media.tailscale" ];
          "192.168.1.5" = [ "home.local" ];
          "192.168.1.6" = [ "laptop.local" ];
          "192.168.1.7" = [ "homelab.local" ];
          "192.168.1.9" = [ "thinkpad.local" ];
          "192.168.1.10" = [ "family.local" ];
          "192.168.1.11" = [ "macmini.local" ];
          "192.168.1.12" = [
            "media.local"
            "prometheus.media.local"
            "radarr.media.local"
            "sonarr.media.local"
            "grafana.media.local"
            "bazarr.media.local"
            "jellyfin.media.local"
            "prowlarr.media.local"
            "deluge.media.local"
            "alloy.media.local"
            "flood.media.local"
          ];
        };
        firewall = {
          enable = true;
          allowedTCPPorts =
            [ ] ++ lib.optionals (config.services.openssh.enable) config.services.openssh.ports;
          logReversePathDrops = false;
          logRefusedUnicastsOnly = false;
          logRefusedPackets = false;
          logRefusedConnections = false;
        };
      };

      environment = {
        systemPackages = [
          pkgs.nmap
          pkgs.dstp
          pkgs.dig
          pkgs.traceroute
          pkgs.inetutils
          pkgs.whois
          pkgs.unixtools.netstat
        ];
      };
    };
}
