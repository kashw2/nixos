{ self, inputs, ... }:
{
  flake.nixosModules.nixvimColorschemes =
    { pkgs, lib, ... }:
    {
      programs.nixvim.colorschemes = {
        catppuccin = {
          enable = true;
          settings = {
            flavour = "macchiato";
            color_overrides = {
              macchiato = {
                mantle = "#090912";
                crust = "#10101A";
                base = "#0B0B14";
                surface0 = "#313244";
                surface1 = "#45475A";
                surface2 = "#585B70";
                overlay0 = "#6C7086";
                overlay1 = "#7F849C";
                overlay2 = "#9399B2";
                subtext0 = "#A6ADC8";
                subtext1 = "#BAC2DE";
                text = "#CDD6F4";
                rosewater = "#F5E0DC";
                flamingo = "#F2CDCD";
                pink = "#F5C2E7";
                mauve = "#CBA6F7";
                red = "#F38BA8";
                maroon = "#EBA0AC";
                peach = "#FAB387";
                yellow = "#F9E2AF";
                green = "#A6E3A1";
                teal = "#94E2D5";
                sky = "#89DCEB";
                sapphire = "#74C7EC";
                blue = "#89B4FA";
                lavender = "#B4BEFE";
              };
            };
          };
        };
      };
    };
}
