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
          "oneuptime/secret" = lib.mkIf config.oneuptime.enable { };
          "oneuptime/encryption_secret" = lib.mkIf config.oneuptime.enable { };
          "oneuptime/register_probe_key" = lib.mkIf config.oneuptime.enable { };
          "oneuptime/probe_key" = lib.mkIf (config.oneuptime.probe.enable || !config.isServer) {
            owner = "keanu";
            group = "keanu";
          };
          "oneuptime/runner_key" = lib.mkIf (config.oneuptime.runner.enable || !config.isServer) {
            owner = "keanu";
            group = "keanu";
          };
          "oneuptime/agent_key/${config.networking.hostName}" = lib.mkIf config.telemetry.agent.enable { };
          "oneuptime/ingestion_token" = lib.mkIf config.services.alloy.enable {
            restartUnits = [ "alloy.service" ];
          };
          "snmp/v3_username" = lib.mkIf config.services.snmpd.enable { };
          "snmp/v3_auth_key" = lib.mkIf config.services.snmpd.enable (
            lib.optionalAttrs (!config.isServer) {
              owner = "keanu";
              group = "keanu";
            }
          );
          "snmp/v3_priv_key" = lib.mkIf config.services.snmpd.enable (
            lib.optionalAttrs (!config.isServer) {
              owner = "keanu";
              group = "keanu";
            }
          );
          "oneuptime/mcp_api_key" = lib.mkIf (!config.isServer) {
            owner = "keanu";
            group = "keanu";
          };
          "github_kashw2_pat" = { };
          "github_tablogs_pat" = { };
          "github_classic_pat" = { };
          "aws_access_key_id" = { };
          "aws_access_key_secret" = { };
          "keanu_password".neededForUsers = true;
          "infracost_api_key" = {
            owner = "keanu";
            group = "keanu";
          };
          "codestats_api_key" = {
            owner = "keanu";
            group = "keanu";
          };
          "git_email_address" = {
            owner = "keanu";
            group = "keanu";
          };
          "terraform_state_passphrase" = lib.mkIf (!config.isServer) {
            owner = "keanu";
            group = "keanu";
          };
        };

        templates."oneuptime.env" = lib.mkIf config.oneuptime.enable {
          content = ''
            ONEUPTIME_SECRET=${config.sops.placeholder."oneuptime/secret"}
            ENCRYPTION_SECRET=${config.sops.placeholder."oneuptime/encryption_secret"}
            REGISTER_PROBE_KEY=${config.sops.placeholder."oneuptime/register_probe_key"}
          '';
          owner = "oneuptime";
          group = "oneuptime";
          mode = "0400";
        };

        templates."oneuptime-probe.env" = lib.mkIf config.oneuptime.probe.enable {
          content = ''
            PROBE_KEY=${config.sops.placeholder."oneuptime/probe_key"}
          '';
          owner = "oneuptime";
          group = "oneuptime";
          mode = "0400";
        };

        templates."oneuptime-runner.env" = lib.mkIf config.oneuptime.runner.enable {
          content = ''
            ONEUPTIME_RUNNER_KEY=${config.sops.placeholder."oneuptime/runner_key"}
          '';
          owner = "oneuptime";
          group = "oneuptime";
          mode = "0400";
        };

        templates."snmpd.conf" = lib.mkIf config.services.snmpd.enable {
          content = ''
            createUser ${config.sops.placeholder."snmp/v3_username"} SHA-256 "${
              config.sops.placeholder."snmp/v3_auth_key"
            }" AES "${config.sops.placeholder."snmp/v3_priv_key"}"
            rouser ${config.sops.placeholder."snmp/v3_username"} priv
            sysName ${config.networking.hostName}
            sysLocation home
            sysContact keanu
          '';
          mode = "0400";
          restartUnits = [ "snmpd.service" ];
        };

        templates."nix-access-tokens" = {
          content = "access-tokens = github.com=${config.sops.placeholder.github_kashw2_pat} github.com/tablogs=${config.sops.placeholder.github_tablogs_pat}";
          group = "wheel";
          mode = "0440";
        };

        templates."codestats-setup.lua" = {
          content = ''
            require('codestats').setup({
              username = "Keanu Ashwell",
              api_key = "${config.sops.placeholder.codestats_api_key}",
            })
          '';
          owner = "keanu";
          group = "keanu";
          mode = "0400";
        };

        templates."git_email_address" = {
          content = ''
            [user]
              email = ${config.sops.placeholder.git_email_address}
          '';
          owner = "keanu";
          group = "keanu";
          mode = "0400";
        };

        templates."credentials" = lib.mkIf (!config.isServer) {
          content = ''
            [default]
            aws_access_key_id = ${config.sops.placeholder.aws_access_key_id}
            aws_secret_access_key = ${config.sops.placeholder.aws_access_key_secret}
          '';
          owner = "keanu";
          group = "keanu";
          mode = "0600";
          path =
            if usingImpermanence then
              "/persist/home/keanu/.aws/credentials"
            else
              "/home/keanu/.aws/credentials";
        };

        templates.".npmrc" = lib.mkIf (!config.isServer) {
          content = ''
            registry=https://registry.npmjs.org/
            @testlab360:registry=https://npm.pkg.github.com/
            @tablogs:registry=https://npm.pkg.github.com/
            @kashw2:registry=https://npm.pkg.github.com/
            //npm.pkg.github.com/:_authToken=${config.sops.placeholder.github_classic_pat}
          '';
          owner = "keanu";
          group = "keanu";
          mode = "0600";
          path = if usingImpermanence then "/persist/home/keanu/.npmrc" else "/home/keanu/.npmrc";
        };
      };
    };
}
