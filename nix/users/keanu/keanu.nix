{ self, inputs, ... }:
{
  flake.nixosModules.keanu =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      usingImpermanence = config.impermanence.enable;
    in
    {

      config = {
        users.groups.keanu = { };

        users.users.keanu = {
          hashedPasswordFile = config.sops.secrets."keanu_password".path;
          isNormalUser = true;
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
              pkgs.google-chrome # For Claude to interact with the browser
              pkgs.firefox-devedition
              pkgs.awscli2
              pkgs.azure-cli
              pkgs.terraform
              pkgs.ansible
              pkgs.openvpn
              pkgs.nautilus
              pkgs.slack
              self.packages.${pkgs.stdenv.hostPlatform.system}.gridcraft
              self.packages.${pkgs.stdenv.hostPlatform.system}.photocraft
              self.packages.${pkgs.stdenv.hostPlatform.system}.deckcraft
              self.packages.${pkgs.stdenv.hostPlatform.system}.vectorcraft
              self.packages.${pkgs.stdenv.hostPlatform.system}.filmcraft
              self.packages.${pkgs.stdenv.hostPlatform.system}.act
              self.packages.${pkgs.stdenv.hostPlatform.system}.oneuptime-cli
              # Only the secret paths are baked in; bb reads the credentials from them at runtime.
              (self.packages.${pkgs.stdenv.hostPlatform.system}.bb.wrap {
                envDefault = {
                  BITBUCKET_EMAIL_FILE = config.sops.secrets."bitbucket/email".path;
                  BITBUCKET_API_TOKEN_FILE = config.sops.secrets."bitbucket/api_token".path;
                };
              })
              pkgs.gh
              pkgs.infracost
              pkgs.opentofu
              pkgs.prettier
              pkgs.nodejs_24
              pkgs.go
              pkgs.gcc # Required by some go projects
              pkgs.bruno
              pkgs.bruno-cli
              pkgs.tmuxp
              pkgs.obsidian
              pkgs.vlc
              pkgs.d2
              pkgs.nixos-anywhere
              pkgs.nixpkgs-review
              pkgs.jetbrains.datagrip
            ]
            ++ lib.optionals (config.isDesktop) [
              inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
              pkgs.obs-studio
            ]
            ++ [
              inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
              (inputs.witr.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
                doCheck = false;
              })
              self.packages.${pkgs.stdenv.hostPlatform.system}.tmux
              pkgs.nix-update
              pkgs.hydra-check
            ];
          openssh.authorizedKeys.keyFiles = (
            map (key: ./.ssh/${key}) (builtins.attrNames (builtins.readDir ./.ssh))
          );
        };

        home-manager.users.keanu = {
          home = {
            stateVersion = config.system.stateVersion;
            file = lib.optionalAttrs (!config.isServer) {
              ".claude/.i-have-adhd-always".text = "";
            };
          }
          // lib.optionalAttrs usingImpermanence {
            # /home/keanu is wiped on boot
            persistence."/persist" = {
              directories = [
                ".ssh"
                ".local/state"
                ".local/share/nix"
                ".local/share/nvim" # neovim state (shada, swap, undo, plugin data)
                ".local/share/zoxide" # zoxide frecency database
                ".local/share/tmux" # tmux-resurrect saved sessions
                ".config/nushell" # nushell history
                ".config/sops" # sops CLI age key
                ".gnupg" # GPG keyring (signing/encryption keys)
                ".docker" # docker registry auth tokens
                ".pki" # NSS certificate DB (custom CA trust for chromium/firefox)
                "nixos"
                "Downloads"
                "Documents"
              ]
              ++ lib.optionals (!config.isServer) [
                ".config/discord"
                ".config/Equicord" # Equicord plugins etc
                ".mozilla"
                ".config/mozilla"
                ".config/Slack" # Slack authentication and settings
                ".aws" # awscli credentials + config
                ".azure" # azure-cli auth
                ".config/gh" # gh cli auth
                ".claude" # claude-code projects, shell snapshots, todos
              ];
              files = lib.optionals (!config.isServer) [
                ".claude.json" # claude-code per-project config + auth
              ];
            };
          };
          mcp-servers = {
            programs = {
              nixos = {
                enable = true;
                package =
                  inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos;
              };
              "sequential-thinking" = {
                enable = true;
                package =
                  inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system}.mcp-server-sequential-thinking;
              };
              terraform = {
                enable = true;
                package =
                  inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.terraform-mcp-server;
              };
              fetch = {
                enable = true;
                package = inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system}.mcp-server-fetch;
              };
              git = {
                enable = true;
                package = inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system}.mcp-server-git;
              };
              memory = {
                enable = true;
                package = inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system}.mcp-server-memory;
              };
              github = {
                enable = true;
                package =
                  inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.github-mcp-server;
                type = "stdio";
                passwordCommand.GITHUB_PERSONAL_ACCESS_TOKEN = [
                  "gh"
                  "auth"
                  "token"
                ];
              };
            };
            settings.servers = {
              bitbucket = lib.mkIf (!config.isServer) {
                command = lib.getExe (
                  self.packages.${pkgs.stdenv.hostPlatform.system}.bb.wrap {
                    envDefault = {
                      BITBUCKET_EMAIL_FILE = config.sops.secrets."bitbucket/email".path;
                      BITBUCKET_API_TOKEN_FILE = config.sops.secrets."bitbucket/api_token".path;
                    };
                  }
                );
                args = [ "mcp" ];
              };
              shortcut = {
                type = "http";
                url = "https://mcp.shortcut.com/mcp";
              };
              azure = {
                command =
                  lib.getExe
                    inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.azure-mcp;
                args = [
                  "server"
                  "start"
                ];
                # nixpkgs' azure-mcp wrapper is missing the ICU/OpenSSL libs .NET dlopens
                env.LD_LIBRARY_PATH = lib.makeLibraryPath [
                  inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.icu
                  inputs.mcp-servers-nix.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.openssl
                ];
              };
              # Headless Firefox for browser QA; bundling only Firefox skips the other Playwright browsers
              playwright = lib.mkIf (!config.isServer) {
                command = lib.getExe (
                  pkgs.playwright-mcp.override {
                    playwright-driver = pkgs.playwright-driver // {
                      browsers = pkgs.playwright-driver.browsers.override {
                        withChromium = false;
                        withChromiumHeadlessShell = false;
                        withWebkit = false;
                      };
                    };
                  }
                );
                args = [
                  "--browser"
                  "firefox"
                  "--headless"
                ];
              };
              # Wrapped CLI creates the token.
              photocraft = {
                command = lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.photocraft "photocraft-cli";
                args = [
                  "mcp"
                  "--bridge"
                  "127.0.0.1:7878"
                  "--control-token-file"
                  "${config.users.users.keanu.home}/.local/state/photocraft/control.token"
                ];
              };
              # Connects to the app on 7979 (nix/packages/vectorcraft.nix), else headless.
              vectorcraft = {
                command = lib.getExe' pkgs.vectorcraft "vectorcraft-cli";
                args = [ "mcp" ];
              };
              # The CLI reads the app's per-port token file itself (nix/packages/gridcraft.nix).
              gridcraft = {
                command = lib.getExe' pkgs.gridcraft "gridcraft-cli";
                args = [
                  "mcp"
                  "--connect"
                  "7676"
                ];
              };
              # Port matches nix/packages/deckcraft.nix; the control server has no auth.
              deckcraft = {
                command = lib.getExe' pkgs.deckcraft "deckcraft-cli";
                args = [
                  "mcp"
                  "--connect"
                  "7575"
                ];
              };
              # The wrapped CLI loads the app's session token itself (nix/packages/filmcraft.nix).
              filmcraft = {
                command = lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.filmcraft "filmcraft-cli";
                args = [
                  "mcp"
                  "--bridge"
                  "127.0.0.1:7777"
                ];
              };
            };
          };
          programs = {
            home-manager.enable = true;
            mcp.enable = !config.isServer;
            claude-code = {
              enable = !config.isServer;
              package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
              enableMcpIntegration = true;
              plugins = {
                inherit (inputs) superpowers i-have-adhd;
              };
              skills = builtins.mapAttrs (name: _: "${inputs.anthropic-skills}/skills/${name}") (
                builtins.readDir "${inputs.anthropic-skills}/skills"
              );
              # Empty strings suppress the Co-Authored-By / "Generated with Claude Code" attribution.
              settings.attribution = {
                commit = "";
                pr = "";
                sessionUrl = false;
              };
              # Top-level effortLevel in user settings only applies to models up to
              # Opus 5 / Fable 5.1; newer models read the per-model key instead.
              settings.effortLevel = "xhigh";
              settings.modelSettings.claude-opus-5-5.effortLevel = "xhigh";
              # Start every session with Claude in Chrome on (browser tools + the
              # bundled /claude-in-chrome skill). claudeInChromeDefaultEnabled only
              # works in the mutable ~/.claude.json, so use the env var instead.
              settings.env.CLAUDE_CODE_ENABLE_CFC = "1";
              settings.hooks =
                let
                  # Gates Shortcut story/epic creation on having read Tablogs KB
                  # article 163 ("Shortcut Story Standards") in the session.
                  shortcutKb163 = lib.getExe (
                    pkgs.writers.writeJSBin "shortcut-kb163-hook" { } (
                      builtins.readFile ./claude-hooks/shortcut-kb163.js
                    )
                  );
                in
                {
                  PreToolUse = [
                    {
                      matcher = "^mcp__plugin_hm_shortcut__(stories|epics)-create$";
                      hooks = [
                        {
                          type = "command";
                          command = shortcutKb163;
                          args = [ "gate" ];
                          statusMessage = "Checking Shortcut story standards (KB 163)";
                        }
                      ];
                    }
                  ];
                  PostToolUse = [
                    {
                      matcher = "^mcp__claude_ai_Tablogs_Admin__get_article$";
                      hooks = [
                        {
                          type = "command";
                          command = shortcutKb163;
                          args = [ "mark" ];
                        }
                      ];
                    }
                  ];
                };
            };
            git = {
              enable = true;
              package = if config.isServer then pkgs.gitMinimal else pkgs.git;
              lfs.enable = true;
              includes = [
                { path = config.sops.templates."git_email_address".path; }
              ];
              settings = {
                user.name = "kashw2";
                user.author.name = "Keanu Ashwell";
                init.defaultBranch = "main";
                core.autocrlf = "input";
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
                equicord = {
                  enable = true;
                  package = inputs.nixcord.packages.${pkgs.stdenv.hostPlatform.system}.equicord;
                };
                openASAR.enable = false;
              };
              config = {
                plugins = {
                  alwaysAnimate.enable = true;
                  anonymiseFileNames = {
                    enable = true;
                    anonymiseByDefault = true;
                  };
                  musicRichPresence.enable = true;
                  callTimer.enable = true;
                  clearUrls.enable = true;
                  copyUserUrls.enable = true;
                  crashHandler.enable = true;
                  disableCallIdle.enable = true;
                  fakeNitro.enable = true;
                  fixSpotifyEmbeds.enable = true;
                  fixYoutubeEmbeds.enable = true;
                  friendInvites.enable = true;
                  gameActivityToggle.enable = true;
                  implicitRelationships.enable = true;
                  memberCount.enable = true;
                  messageLogger.enable = true;
                  noBlockedMessages.enable = true;
                  relationshipNotifier.enable = true;
                  shikiCodeblocks.enable = true;
                  silentTyping.enable = true;
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
