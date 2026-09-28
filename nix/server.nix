{ self, inputs, ... }:
{
  flake.nixosModules.serverTemplate =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # ip_local_port_range spans the service ports below, so anything the host
      # listens on can be taken as an outbound source port before the service
      # binds it.
      portRangeFloor = 1024;
      reservedPorts = lib.sort (a: b: a < b) (
        lib.filter (port: port >= portRangeFloor) (
          lib.unique (
            config.networking.firewall.allowedTCPPorts
            ++ config.networking.firewall.allowedUDPPorts
            ++ lib.optionals config.oneuptime.enable [
              config.oneuptime.port
              config.oneuptime.probe.port
              config.oneuptime.runner.port
            ]
            ++ lib.optional config.services.postgresql.enable config.services.postgresql.settings.port
            ++ lib.optionals config.services.clickhouse.enable [
              8123
              9000
              9004
              9005
              9009
              9181
              9234
              9363
            ]
            ++ lib.optionals config.services.resolved.enable [
              53
              5353
              5355
            ]
            ++ lib.optional config.services.jellyfin.enable 7359
            ++ lib.concatMap (vhost: map (l: l.port) vhost.listen) (
              lib.attrValues config.services.nginx.virtualHosts
            )
            ++ lib.optional (
              config.services.redis.servers ? oneuptime
            ) config.services.redis.servers.oneuptime.port
            ++ lib.optionals config.services.alloy.enable [
              4317
              4318
              12345
            ]
            ++ lib.optional config.services.prometheus.exporters.postgres.enable config.services.prometheus.exporters.postgres.port
          )
        )
      );
    in
    {

      imports = [
        self.nixosModules.environment
      ];

      isServer = true;
      isDesktop = false;
      isLaptop = false;

      boot = {
        loader.systemd-boot.enable = true;
        loader.systemd-boot.configurationLimit = 10;
        loader.efi.canTouchEfiVariables = true;

        kernel.sysctl = {
          "net.core.rmem_max" = 67108864;
          "net.core.wmem_max" = 67108864;
          "net.ipv4.tcp_rmem" = "4096 87380 67108864";
          "net.ipv4.tcp_wmem" = "4096 65536 67108864";
          "net.core.somaxconn" = 4096;
          "net.core.netdev_max_backlog" = 8192;
          "net.ipv4.ip_local_port_range" = "1024 65535";
          "net.ipv4.ip_local_reserved_ports" = lib.concatMapStringsSep "," toString reservedPorts;
          "net.ipv4.tcp_tw_reuse" = 1;
          "net.ipv4.tcp_slow_start_after_idle" = 0;
          "net.ipv4.tcp_fin_timeout" = 15;
          "net.ipv4.tcp_max_syn_backlog" = 8192;
          "net.ipv4.tcp_mtu_probing" = 1;
          "net.core.optmem_max" = 2097152;
          "net.ipv4.tcp_max_tw_buckets" = 65536;
          "net.core.default_qdisc" = "fq";
          "net.ipv4.tcp_congestion_control" = "bbr";
        };
      };
    };
}
