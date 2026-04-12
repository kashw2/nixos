{ self, inputs, ... }:
{
  flake.nixosModules.telemetry =
    { pkgs, lib, ... }:
    {

      imports = [
        self.nixosModules.basicTelemetry
        self.nixosModules.alloy
        self.nixosModules.loki
        self.nixosModules.grafana
        self.nixosModules.tempo
        self.nixosModules.prometheus
      ];

      options.features.telemetry.role = lib.mkOption {
        type = lib.types.enum [
          "host"
          "client"
        ];
        default = "client";
        description = "Whether this machine is a telemetry host (runs the LGTP stack) or a client (only exports metrics).";
      };

    };
}
