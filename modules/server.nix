{ self, inputs, ... }:
{
  flake.nixosModules.serverTemplate =
    { pkgs, lib, ... }:
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
