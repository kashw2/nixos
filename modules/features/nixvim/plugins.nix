{ self, inputs, ... }:
{
  flake.nixosModules.nixvimPlugins =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.nixvim.extraPlugins = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.atone-nvim
        self.packages.${pkgs.stdenv.hostPlatform.system}.codestats
      ]
      ++ lib.optionals (!config.isServer) [
        self.packages.${pkgs.stdenv.hostPlatform.system}.bruno-nvim
      ];

      programs.nixvim.extraConfigLua = ''
        require("atone").setup({})
        local codestats_key_file = io.open("${config.sops.secrets."codestats_api_key".path}", "r")
        if codestats_key_file then
          local codestats_key = codestats_key_file:read("*a"):gsub("%s+$", "")
          codestats_key_file:close()
          require('codestats').setup({
            username = "Keanu Ashwell",
            api_key = codestats_key,
          })
        end
      '';

      programs.nixvim.plugins = {
        nix.enable = true;
        nix-develop.enable = true;
        claude-code = {
          enable = !config.isServer;
          settings = {
            command =
              let
                hmClaude = config.home-manager.users.keanu.programs.claude-code;
              in
              if hmClaude.enable then lib.getExe hmClaude.finalPackage else lib.getExe pkgs.claude-code;
            window.position = "float";
            window.float = {
              width = "80%";
              height = "85%";
              row = "center";
              col = "center";
              border = "rounded";
              relative = "editor";
            };
            git.use_git_root = false;
          };
        };
        web-devicons.enable = true;
        snacks.enable = true;
        auto-session.enable = true;
        bufdelete.enable = true;
        ts-autotag.enable = true;
        todo-comments.enable = true;
        telescope.enable = true;
        fidget.enable = true;
        image.enable = true;
        colorizer.enable = true;
        render-markdown.enable = true;
        bufferline.enable = true;
        lensline.enable = true;
        lualine.enable = true;
        gitsigns.enable = true;
        tiny-glimmer.enable = true;
        cursorline.enable = true;
        vim-dadbod.enable = !config.isServer;
        vim-dadbod-completion.enable = !config.isServer;
        vim-dadbod-ui.enable = !config.isServer;
        diagram.enable = !config.isServer;
        git-conflict.enable = true;
        barbecue.enable = true;
        lazygit.enable = true;
        nvim-lightbulb.enable = true;
        mini-pairs.enable = true;
        mini-cmdline.enable = true;
        mini-move = {
          enable = true;
          settings.mappings = {
            up = "<A-S-Up>";
            right = "<A-S-Right>";
            down = "<A-S-Down>";
            left = "<A-S-Left>";
            line_up = "<A-S-Up>";
            line_right = "<A-S-Right>";
            line_down = "<A-S-Down>";
            line_left = "<A-S-Left>";
          };
        };
        hlchunk = {
          enable = true;
          settings = {
            blank.enable = false;
            chunk = {
              chars = {
                horizontal_line = "─";
                left_bottom = "╰";
                left_top = "╭";
                right_arrow = "─";
                vertical_line = "│";
              };
              enable = true;
              exclude_filetypes = {
                lazyterm = true;
                neo-tree = true;
              };
              style.fg = "#91bef0";
              use_treesitter = true;
            };
            indent = {
              chars = [ "│" ];
              exclude_filetypes = {
                lazyterm = true;
                neo-tree = true;
              };
              style.fg = "#45475a";
              use_treesitter = true;
            };
            line_num = {
              style = "#91bef0";
              use_treesitter = true;
            };
          };
        };
        fastaction = {
          enable = true;
          settings.dismiss_keys = [
            "<Esc>"
            "q"
          ];
        };
        blame = {
          enable = true;
          settings.date_format = "%d/%m/%y";
        };
        blink-cmp = {
          enable = true;
          settings = {
            appearance.kind_icons = {
              Class = "󱡠";
              Color = "󰏘";
              Constant = "󰏿";
              Constructor = "󰒓";
              Enum = "󰦨";
              EnumMember = "󰦨";
              Event = "󱐋";
              Field = "󰜢";
              File = "󰈔";
              Folder = "󰉋";
              Function = "󰊕";
              Interface = "󱡠";
              Keyword = "󰻾";
              Method = "󰊕";
              Module = "󰅩";
              Operator = "󰪚";
              Property = "󰖷";
              Reference = "󰬲";
              Snippet = "󱄽";
              Struct = "󱡠";
              Text = "󰉿";
              TypeParameter = "󰬛";
              Unit = "󰪚";
              Value = "󰦨";
              Variable = "󰆦";
            };
            appearance.nerd_font_variant = "mono";
            signature.enabled = true;
            completion = {
              documentation.auto_show = true;
              ghost_text.enabled = true;
            };
            keymap.preset = "enter";
            sources = {
              default = [
                "lsp"
                "path"
                "buffer"
              ];
            };
          };
        };
        nvim-tree = {
          enable = true;
          settings = {
            git.enable = true;
            view.width = 30;
            filters = {
              dotfiles = false;
              git_ignored = false;
            };
            update_focused_file.enable = true;
            renderer = {
              highlight_git = "name";
              highlight_diagnostics = "name";
              highlight_hidden = "name";
              indent_markers.enable = true;
              icons.show = {
                git = false;
                folder_arrow = false;
              };
            };
          };
        };
        conform-nvim = {
          enable = true;
          settings = {
            ignore_errors = false;
            format_on_save.timeoutMs = 500;
            formatters_by_ft = {
              nix = [ "nixfmt" ];
              typescript = [ "prettier" ];
              javascript = [ "prettier" ];
              typescriptreact = [ "prettier" ];
              javascriptreact = [ "prettier" ];
              css = [ "prettier" ];
              html = [ "prettier" ];
              markdown = [ "prettier" ];
              terraform = [ "terraform_fmt" ];
              go = [ "gofmt" ];
              json = [ "prettier" ];
              sh = [ "shfmt" ];
              _ = [ "trim_whitespace" ];
            }
            // lib.optionalAttrs (!config.isServer) {
              yaml = [ "yq" ];
              prisma = [ "prismaFmt" ];
            };
            formatters = lib.optionalAttrs (!config.isServer) {
              prismaFmt = {
                command = lib.getExe pkgs.prisma;
                args = [
                  "format"
                  "--schema"
                  "$FILENAME"
                ];
                stdin = false;
              };
            };
          };
        };
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
          grammarPackages =
            let
              g = pkgs.vimPlugins.nvim-treesitter.builtGrammars;
            in
            [
              g.bash # bashls
              g.dockerfile # docker_language_server
              g.gomod # gopls
              g.gosum # gopls
              g.gowork # gopls
              g.helm # helm_ls
              g.ini # systemd_lsp (no dedicated systemd grammar)
              g.javascript # conform (javascript/javascriptreact)
              g.jq # jqls
              g.json # jsonls
              g.json5 # jsonls
              g.nix # nixd
              g.nu # nushell
              g.tsx # conform (typescriptreact)
              g.yaml # yamlls, docker_compose_language_service
              g.markdown # prettier (markdown)
              g.markdown_inline # render-markdown.nvim needs this alongside markdown
              g.lua # extraConfigLua + editing this config
              g.luadoc
              g.query # treesitter .scm query files
              g.regex
              g.comment # todo-comments highlighting
              g.vim # vimscript
              g.vimdoc # :help buffers
              g.diff # gitsigns / git-conflict diffs
              g.gitcommit # commit message buffers
              g.git_rebase # interactive rebase buffers
              g.toml # Cargo.toml and assorted config
            ]
            ++ lib.optionals (!config.isServer) [
              g.cmake # cmake
              g.css # cssls, tailwindcss
              g.go # gopls
              g.groovy # gradle_ls
              g.hcl # terraformls, tflint
              g.html # html, tailwindcss
              g.hyprlang # hyprls
              g.prisma # prismaFmt
              g.python # pylsp
              g.rust # rust_analyzer
              g.scala # metals
              g.sql # postgres_lsp, vim-dadbod
              g.terraform # conform (terraform_fmt)
              g.typescript # conform (typescript)
              self.packages.${pkgs.stdenv.hostPlatform.system}.tree-sitter-bruno # bruno-nvim
            ];
        };
        toggleterm = {
          enable = true;
          settings = {
            direction = "float";
            open_mapping = "[[<C-t>]]";
          };
        };
        smart-splits = {
          enable = true;
          settings = {
            ignored_events = [
              "BufEnter"
              "WinEnter"
            ];
            silent = true;
          };
        };
      };
    };
}
