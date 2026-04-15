{ self, inputs, ... }:
{
  flake.nixosModules.keanu =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {

      config = {
        users.groups.keanu = { };

        users.users.keanu = {
          hashedPasswordFile = config.sops.secrets."keanu_password".path;
          createHome = true;
          isNormalUser = true;
          home = "/home/keanu";
          group = "keanu";
          extraGroups = [
            "wheel"
            "adm"
          ]
          ++ lib.optionals config.virtualisation.docker.enable [
            "docker"
          ]
          ++ lib.optionals config.networking.networkmanager.enable [
            "networkmanager"
          ]
          ++ lib.optionals config.services.pipewire.enable [
            "audio"
          ]
          ++ lib.optionals config.virtualisation.libvirtd.enable [
            "libvirtd"
            "qemu-libvirtd"
          ];
          shell = self.packages.${pkgs.stdenv.hostPlatform.system}.nushell;
          packages =
            lib.optionals (!config.isServer) [
              pkgs.firefox-devedition
              pkgs.awscli2
              pkgs.azure-cli
              pkgs.terraform
              pkgs.ansible
              pkgs.antigravity
              pkgs.claude-code
              pkgs.opencode
              pkgs.openvpn
              pkgs.nautilus
              pkgs.slack
              pkgs.act
              pkgs.gh
              pkgs.infracost
              pkgs.prettier
              pkgs.nodejs_24
              pkgs.bruno
              pkgs.vlc
              pkgs.obs-studio
              pkgs.d2
              pkgs.nixos-anywhere
            ]
            ++ [
              inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
              pkgs.nu_scripts
              pkgs.nixpkgs-review
              pkgs.nix-update
              pkgs.hydra-check
              pkgs.sops
              pkgs.ssh-to-age
            ];
          openssh.authorizedKeys.keyFiles = (
            map (key: ./.ssh/${key}) (builtins.attrNames (builtins.readDir ./.ssh))
          );
        };

        home-manager.users.keanu = {
          home.stateVersion = config.system.stateVersion;
          mcp-servers.programs = {
            nixos.enable = true;
            "sequential-thinking".enable = true;
            terraform.enable = true;
            fetch.enable = true;
            git.enable = true;
            memory.enable = true;
          };
          programs = {
            home-manager.enable = true;
            mcp.enable = !config.isServer;
            opencode = {
              enable = !config.isServer;
              enableMcpIntegration = true;
              settings = {
                provider = {
                  lmstudio = {
                    options.baseURL = "http://localhost:1234/v1";
                    models = {
                      "qwen3.5:9b" = {
                        _launch = true;
                        name = "qwen3.5:9b";
                      };
                    };
                  };
                };
              };
            };
            claude-code = {
              enable = !config.isServer;
              enableMcpIntegration = true;
            };
            git = {
              enable = true;
              lfs.enable = true;
              settings = {
                user.name = "kashw2";
                user.email = "supra4keanu@hotmail.com";
                user.author.name = "Keanu Ashwell";
                init.defaultBranch = "main";
                core.autocrlf = "input";
                color.ui = true;
                alias = {
                  br = "branch";
                  cl = "clone";
                  co = "checkout";
                  cob = "checkout -b";
                  cp = "cherry-pick";
                  cpa = "!git cherry-pick --abort && setterm -foreground red && echo Aborted && setterm -foreground default";
                  cpc = "cherry-pick --continue";
                  db = "branch -D";
                  fa = "!git fetch --all && setterm -foreground green && echo Fetch complete && setterm -foreground default";
                  logol = "log --oneline";
                  logg = "log --oneline --graph --decorate";
                  rb = "rebase";
                  rba = "!git rebase --abort && setterm -foreground red && echo Aborted && setterm -foreground default";
                  rbc = "rebase --continue";
                  rbs = "rebase --skip";
                  rbom = "rebase origin/main";
                  rs = "reset";
                  rso = "reset origin";
                  rsoh = "reset origin/main --hard";
                  rsh = "reset --hard";
                  rf = "reflog";
                };
              };
            };
            nixcord = {
              # Only enable if discord is installed for this user, that way servers aren't getting it
              enable = !config.isServer;
              discord = {
                vencord.enable = true;
                openASAR.enable = false;
              };
              config = {
                plugins = {
                  alwaysAnimate.enable = true;
                  anonymiseFileNames = {
                    enable = true;
                    anonymiseByDefault = true;
                  };
                  appleMusicRichPresence.enable = true;
                  LastFMRichPresence.enable = true;
                  callTimer.enable = true;
                  ClearURLs.enable = true;
                  CopyUserURLs.enable = true;
                  crashHandler.enable = true;
                  disableCallIdle.enable = true;
                  fakeNitro.enable = true;
                  fixSpotifyEmbeds.enable = true;
                  fixYoutubeEmbeds.enable = true;
                  friendInvites.enable = true;
                  friendsSince.enable = true;
                  gameActivityToggle.enable = true;
                  implicitRelationships.enable = true;
                  memberCount.enable = true;
                  messageLogger.enable = true;
                  noBlockedMessages.enable = true;
                  relationshipNotifier.enable = true;
                  shikiCodeblocks.enable = true;
                  silentTyping.enable = true;
                  sortFriendRequests.enable = true;
                  spotifyCrack.enable = true;
                  typingTweaks.enable = true;
                  youtubeAdblock.enable = true;
                  showHiddenChannels.enable = true;
                };
              };
            };
          };
        };

      };
    };
}
