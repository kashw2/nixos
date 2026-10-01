{ self, inputs, ... }:
{
  flake.deploy = {
    sshUser = "keanu";
    user = "root";
    nodes = builtins.mapAttrs (name: configuration: {
      hostname = "${name}.local";
      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos configuration;
    }) self.nixosConfigurations;
  };

  perSystem =
    { system, ... }:
    {
      checks = builtins.removeAttrs (inputs.deploy-rs.lib.${system}.deployChecks self.deploy) [
        "deploy-activate"
      ];
      packages.deploy-rs = inputs.deploy-rs.packages.${system}.default;
    };
}
