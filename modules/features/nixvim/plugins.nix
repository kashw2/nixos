{ self, inputs, ... }:
{
  flake.nixosModules.nixvimPlugins =
    { config, pkgs, lib, ... }:
    {
      programs.nixvim.extraPlugins = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.atone-nvim
        self.packages.${pkgs.stdenv.hostPlatform.system}.codestats
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
        vim-dadbod.enable = true;
        vim-dadbod-completion.enable = true;
        vim-dadbod-ui.enable = true;
        diagram.enable = true;
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
              yaml = [ "yq" ];
              sh = [ "shfmt" ];
              _ = [ "trim_whitespace" ];
            };
          };
        };
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
          grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
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
