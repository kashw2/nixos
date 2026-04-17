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

      # Ensure the persist-side .ssh directory exists with keanu ownership
      # and 0700 before sops places secrets into it — sops would otherwise
      # create it as root:root 0755, which ssh-client rejects.
      #
      # Also stage a user-owned copy of the age key at the sops CLI default
      # path so `sops secrets/...` works for keanu without sudo. `C` copies
      # once on first boot; rotating the source won't refresh — delete the
      # copy to retrigger.
      systemd.tmpfiles.rules = [
        "d /persist/home/keanu 0700 keanu keanu -"
        "d /persist/home/keanu/.ssh 0700 keanu keanu -"
        "d /persist/home/keanu/.config 0700 keanu keanu -"
        "d /persist/home/keanu/.config/sops 0700 keanu keanu -"
        "d /persist/home/keanu/.config/sops/age 0700 keanu keanu -"
        "C /persist/home/keanu/.config/sops/age/keys.txt 0400 keanu keanu - /persist/var/lib/sops-nix/key.txt"
      ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;

        # Read both the age key and the SSH host key fallback directly from
        # /persist rather than via their impermanence bind-mount targets
        # (/var/lib/sops-nix, /etc/ssh). The impermanence bind mounts are
        # stage-2 systemd units and can race the sops `neededForUsers`
        # activation step on fresh boots — when they lose, decryption
        # silently fails and users with hashedPasswordFile end up
        # passwordless. /persist itself is mounted in stage 1 via
        # neededForBoot, so these paths are always present when sops runs.
        age.keyFile = "/persist/var/lib/sops-nix/key.txt";
        age.sshKeyPaths = lib.mkForce [
          "/persist/etc/ssh/ssh_host_ed25519_key"
        ];

        secrets = {
          # Write directly into /persist. Home-manager impermanence
          # bind-mounts /persist/home/keanu/.ssh → /home/keanu/.ssh at
          # session start, so secrets placed at /home/keanu/.ssh/... during
          # sops activation get shadowed by the bind mount. Writing to the
          # source of the bind mount is equivalent and race-free.
          "ssh/${config.networking.hostName}/id_ed25519" = {
            owner = "keanu";
            group = "keanu";
            mode = "0600";
            path = "/persist/home/keanu/.ssh/id_ed25519";
          };
          # This doesn't need to be a secret, but home manager doesn't support setting the mode
          "ssh/${config.networking.hostName}/id_ed25519_pub" = {
            owner = "keanu";
            group = "keanu";
            mode = "0644";
            path = "/persist/home/keanu/.ssh/id_ed25519.pub";
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
