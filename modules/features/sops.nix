{ self, inputs, ... }:
{
  flake.nixosModules.sops =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      usingImpermanence = config.impermanence.enable;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      environment.systemPackages = [
        pkgs.age
        pkgs.ssh-to-age
        pkgs.sops
      ];

      # On impermanence hosts: ensure /persist/home/keanu/.ssh exists with
      # keanu ownership and 0700 before sops places secrets into it (sops
      # would otherwise create it as root:root 0755, which ssh-client
      # rejects), and stage a user-owned copy of the age key at the sops
      # CLI default path so `sops secrets/...` works for keanu without
      # sudo. We target the bind-mount source — home-manager mounts
      # /persist/home/keanu over /home/keanu in stage 2 and would shadow
      # rules touching the /home/keanu side. `C` copies once on first
      # boot; rotating the source won't refresh — delete the copy to
      # retrigger.
      #
      # On non-impermanence hosts /home/keanu is created normally and
      # home-manager owns ~/.ssh, so no tmpfiles staging is required.
      systemd.tmpfiles.rules = lib.mkIf usingImpermanence [
        "d /persist/home/keanu 0700 keanu keanu -"
        "d /persist/home/keanu/.ssh 0700 keanu keanu -"
        "d /persist/home/keanu/.config 0700 keanu keanu -"
        "d /persist/home/keanu/.config/sops 0700 keanu keanu -"
        "d /persist/home/keanu/.config/sops/age 0700 keanu keanu -"
        "C /persist/home/keanu/.config/sops/age/keys.txt 0400 keanu keanu - /persist/var/lib/sops-nix/key.txt"
      ];

      sops = {
        defaultSopsFile = ../../secrets/secrets.yaml;

        # On impermanence hosts, read the age key and SSH host key fallback
        # directly from /persist rather than via their bind-mount targets
        # (/var/lib/sops-nix, /etc/ssh). Those bind mounts are stage-2
        # systemd units and can race the sops `neededForUsers` activation
        # on fresh boots — when they lose, decryption silently fails and
        # users with hashedPasswordFile end up passwordless. /persist
        # itself is mounted in stage 1 via neededForBoot, so the /persist
        # paths are always present when sops runs. The mkForce on
        # sshKeyPaths replaces the sops-nix default rather than appending.
        #
        # On non-impermanence hosts the keyFile is placed by the installer
        # ISO from a USB-provided keys.txt on first install. On existing
        # deployed hosts that file may not exist and sops-nix falls back
        # to sshKeyPaths.
        age.keyFile =
          if usingImpermanence then "/persist/var/lib/sops-nix/key.txt" else "/var/lib/sops-nix/key.txt";
        age.sshKeyPaths =
          if usingImpermanence then
            lib.mkForce [ "/persist/etc/ssh/ssh_host_ed25519_key" ]
          else
            [ "/etc/ssh/ssh_host_ed25519_key" ];

        secrets = {
          # Write to the source of the home-manager .ssh bind mount on
          # impermanence hosts (/persist/home/keanu/.ssh) so secrets aren't
          # shadowed when the bind activates. On non-impermanence hosts
          # there is no bind mount, so /home/keanu/.ssh is the real path.
          "ssh/${config.networking.hostName}/id_ed25519" = {
            owner = "keanu";
            group = "keanu";
            mode = "0600";
            path =
              if usingImpermanence then "/persist/home/keanu/.ssh/id_ed25519" else "/home/keanu/.ssh/id_ed25519";
          };
          # This doesn't need to be a secret, but home manager doesn't support setting the mode
          "ssh/${config.networking.hostName}/id_ed25519_pub" = {
            owner = "keanu";
            group = "keanu";
            mode = "0644";
            path =
              if usingImpermanence then
                "/persist/home/keanu/.ssh/id_ed25519.pub"
              else
                "/home/keanu/.ssh/id_ed25519.pub";
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
