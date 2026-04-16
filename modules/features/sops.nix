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

        # Primary key path, placed by the installer ISO from a USB-provided
        # keys.txt on first install so sops-nix can decrypt on first boot.
        # On existing deployed hosts this file doesn't exist and sops-nix
        # falls back to sshKeyPaths above.
        age.keyFile = "/var/lib/sops-nix/key.txt";

        # Read the sops age decryption key from its persistent location
        # rather than /etc/ssh. The impermanence `files` bind mount that
        # puts the key at /etc/ssh/ssh_host_ed25519_key is a stage-2
        # systemd unit and can race the sops `neededForUsers` activation
        # step on fresh boots when it loses, decryption silently fails
        # and users with hashedPasswordFile end up passwordless.
        # Hosts without impermanence keep the default /etc/ssh path set
        # in modules/features/sops.nix.
        age.sshKeyPaths = lib.mkForce [
          "/persist/etc/ssh/ssh_host_ed25519_key"
        ];

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
          "github_kashw2_pat" = { };
          "github_tablogs_pat" = { };
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
          content = "access-tokens = github.com=${config.sops.placeholder.github_kashw2_pat} github.com/tablogs=${config.sops.placeholder.github_tablogs_pat}";
          group = "wheel";
          mode = "0440";
        };
      };
    };
}
