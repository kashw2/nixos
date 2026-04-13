{ self, inputs, ... }:
{
  flake.nixosModules.sops =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      environment.systemPackages = [
        pkgs.age
        pkgs.ssh-to-age
        pkgs.sops
      ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        secrets = {
          "ssh/${config.networking.hostName}/id_ed25519" = {
            owner = "keanu";
            group = "keanu";
            mode = "0600";
            path = "/home/keanu/.ssh/id_ed25519";
          };
          # This doesn't need to be a secret, but home manager doesn't support setting the mode
          "ssh/${config.networking.hostName}/id_ed25519_pub" = {
            owner = "keanu";
            group = "keanu";
            mode = "0644";
            path = "/home/keanu/.ssh/id_ed25519.pub";
          };
          "tailscale" = { };
          "grafana_secret_key" = lib.mkIf (config.services.grafana.enable) {
            owner = "grafana";
            group = "grafana";
          };
          "github_pat" = { };
          "keanu_password".neededForUsers = true;
          "infracost_api_key" = {
            owner = "keanu";
            group = "keanu";
          };
          "codestats_api_key" = {
            owner = "keanu";
            group = "keanu";
          };
        };

        templates."nix-access-tokens" = {
          content = "access-tokens = github.com=${config.sops.placeholder.github_pat}";
        };
      };
    };
}
