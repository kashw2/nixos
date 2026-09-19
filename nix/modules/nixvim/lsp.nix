{ inputs, ... }:
{
  config.flake.nixvimModules.lsp =
    {
      pkgs,
      config,
      ...
    }:
    {
      plugins.lsp.enable = true;
      plugins.lsp-format.enable = !config.plugins.conform-nvim.enable;
      lsp = {
        inlayHints.enable = true;
        servers = {
          ansiblels.enable = !config.host.isServer;
          jqls.enable = true;
          pylsp.enable = !config.host.isServer;
          rust_analyzer.enable = !config.host.isServer;
          tailwindcss.enable = !config.host.isServer;
          postgres_lsp.enable = !config.host.isServer;
          prismals.enable = !config.host.isServer;
          systemd_lsp.enable = true;
          helm_ls.enable = true;
          cssls.enable = !config.host.isServer;
          bashls.enable = true;
          cmake.enable = !config.host.isServer;
          eslint.enable = !config.host.isServer;
          ts_ls.enable = !config.host.isServer;
          html.enable = !config.host.isServer;
          gradle_ls.enable = !config.host.isServer;
          docker_compose_language_service.enable = true;
          docker_language_server.enable = true;
          gopls.enable = !config.host.isServer;
          hyprls.enable = !config.host.isServer;
          terraformls.enable = !config.host.isServer;
          tflint.enable = !config.host.isServer;
          typos_lsp.enable = true;
          metals.enable = !config.host.isServer;
          roslyn_ls.enable = !config.host.isServer;
          nixd = {
            enable = true;
            package = inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd;
          };
          lua_ls = {
            enable = !config.host.isServer;
            config.settings.Lua = {
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
}
