{ self, inputs, ... }:
{
  config.flake.nixvimModules.plugins =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      extraPlugins = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.atone-nvim
        self.packages.${pkgs.stdenv.hostPlatform.system}.codestats
      ]
      ++ lib.optionals (!config.host.isServer) [
        self.packages.${pkgs.stdenv.hostPlatform.system}.bruno-nvim
      ];

      extraConfigLua = ''
        require("atone").setup({})
      ''
      + lib.optionalString (config.host.codestatsSetup != null) ''
        pcall(dofile, "${config.host.codestatsSetup}")
      ''
      + lib.optionalString (!config.host.isServer) ''
        local tuicr = require("toggleterm.terminal").Terminal:new({
          cmd = "${lib.getExe' inputs.tuicr.packages.${pkgs.stdenv.hostPlatform.system}.default "tuicr"}",
          direction = "float",
          float_opts = { border = "rounded" },
          hidden = true,
        })
        vim.keymap.set("n", "cr", function() tuicr:toggle() end, { silent = true })
      '';

      plugins = {
        nix.enable = true;
        nix-develop.enable = true;
        claude-code = {
          enable = !config.host.isServer;
          settings = {
            command = config.host.claudeCommand;
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
        auto-session = {
          enable = true;
          settings.restore_error_handler.__raw = ''
            function()
              return true
            end
          '';
        };
        bufdelete.enable = true;
        ts-autotag.enable = !config.host.isServer;
        todo-comments.enable = true;
        telescope = {
          enable = true;
          extensions.fzf-native.enable = true;
        };
        fidget.enable = true;
        image = {
          enable = !config.host.isServer;
          settings.hijack_file_patterns = [
            "*.png"
            "*.jpg"
            "*.jpeg"
            "*.gif"
            "*.webp"
            "*.avif"
            "*.svg"
          ];
        };
        colorizer.enable = true;
        render-markdown.enable = true;
        bufferline.enable = true;
        lensline.enable = true;
        lualine.enable = true;
        gitsigns.enable = true;
        illuminate.enable = true;
        tiny-glimmer.enable = true;
        diagram.enable = !config.host.isServer;
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
            git = {
              enable = true;
              timeout = 2000;
            };
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
          autoInstall = {
            enable = true;
            overrides = {
              nixfmt = inputs.nixfmt.packages.${pkgs.stdenv.hostPlatform.system}.default;
              yq = pkgs.yq-go;
              terraform_fmt = pkgs.terraform;
            };
          };
          settings = {
            ignore_errors = false;
            format_on_save.timeoutMs = 500;
            formatters_by_ft = {
              nix = [ "nixfmt" ];
              sh = [ "shfmt" ];
              _ = [ "trim_whitespace" ];
            }
            // lib.optionalAttrs (!config.host.isServer) {
              markdown = [ "prettier" ];
              json = [ "prettier" ];
              typescript = [ "prettier" ];
              javascript = [ "prettier" ];
              typescriptreact = [ "prettier" ];
              javascriptreact = [ "prettier" ];
              css = [ "prettier" ];
              html = [ "prettier" ];
              terraform = [ "terraform_fmt" ];
              go = [ "gofmt" ];
              yaml = [ "yq" ];
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
              g.ini # systemd_lsp (no dedicated systemd grammar)
              g.jq # jqls
              g.json # jsonls
              g.json5 # jsonls
              g.nix # nixd
              g.nu # nushell
              g.yaml # yamlls, docker_compose_language_service
              g.markdown # prettier (markdown)
              g.markdown_inline # render-markdown.nvim needs this alongside markdown
              g.query # treesitter .scm query files
              g.regex
              g.comment # todo-comments highlighting
              g.vim # vimscript
              g.vimdoc # :help buffers
              g.diff # gitsigns / git-conflict diffs
              g.gitcommit # commit message buffers
              g.git_rebase # interactive rebase buffers
            ]
            ++ lib.optionals (!config.host.isServer) [
              g.toml # Cargo.toml and assorted config
              g.luadoc
              g.tsx # conform (typescriptreact)
              g.javascript # conform (javascript/javascriptreact)
              g.lua # extraConfigLua + editing this config
              g.gomod # gopls
              g.gosum # gopls
              g.gowork # gopls
              g.helm # helm_ls
              g.cmake # cmake
              g.css # cssls, tailwindcss
              g.go # gopls
              g.groovy # gradle_ls
              g.hcl # terraformls, tflint
              g.html # html, tailwindcss
              g.hyprlang # hyprls
              g.prisma # prismals
              g.python # pylsp
              g.rust # rust_analyzer
              g.scala # metals
              g.sql # postgres_lsp
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
