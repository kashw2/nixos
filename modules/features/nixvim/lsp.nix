{ self, inputs, ... }:
{
  flake.nixosModules.nixvimLsp =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.nixvim = {
        plugins.lsp.enable = true;
        plugins.lsp-format.enable = !config.programs.nixvim.plugins.conform-nvim.enable;
        lsp = {
          inlayHints.enable = true;
          servers = {
            ansiblels.enable = !config.isServer;
            jqls.enable = true;
            pylsp.enable = !config.isServer;
            rust_analyzer.enable = !config.isServer;
            tailwindcss.enable = !config.isServer;
            postgres_lsp.enable = !config.isServer;
            systemd_lsp.enable = true;
            helm_ls.enable = true;
            cssls.enable = !config.isServer;
            bashls.enable = true;
            cmake.enable = !config.isServer;
            eslint.enable = !config.isServer;
            ts_ls.enable = !config.isServer;
            html.enable = !config.isServer;
            gradle_ls.enable = !config.isServer;
            docker_compose_language_service.enable = true;
            docker_language_server.enable = true;
            gopls.enable = !config.isServer;
            hyprls.enable = !config.isServer;
            terraformls.enable = !config.isServer;
            tflint.enable = !config.isServer;
            typos_lsp.enable = true;
            metals.enable = !config.isServer;
            nixd.enable = true;
            lua_ls = {
              enable = true;
              settings.Lua = {
                workspace.library.__raw = "vim.api.nvim_get_runtime_file('', true)";
                telemetry.enable = false;
              };
            };
            nushell.enable = true;
            yamlls.enable = true;
            jsonls.enable = true;
          };
        };
      };
    };
}
