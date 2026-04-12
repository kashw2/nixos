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
            ansiblels.enable = true;
            jqls.enable = true;
            pylsp.enable = true;
            rust_analyzer.enable = true;
            tailwindcss.enable = true;
            postgres_lsp.enable = true;
            systemd_lsp.enable = true;
            helm_ls.enable = true;
            cssls.enable = true;
            bashls.enable = true;
            cmake.enable = true;
            eslint.enable = true;
            html.enable = true;
            gradle_ls.enable = true;
            docker_compose_language_service.enable = true;
            docker_language_server.enable = true;
            gopls.enable = true;
            hyprls.enable = true;
            terraformls.enable = true;
            tflint.enable = true;
            typos_lsp.enable = true;
            metals.enable = true;
            nixd.enable = true;
            nushell.enable = true;
            yamlls.enable = true;
            jsonls.enable = true;
          };
        };
      };
    };
}
