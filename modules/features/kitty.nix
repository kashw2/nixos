{ self, inputs, ... }:
{
  flake.wrappers.kitty =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.kitty;
        # Config lives in its own store directory (writeTextDir) rather than a
        # bare /nix/store file, so kitty's live-reload watcher watches a
        # single-file dir instead of all of /nix/store
        flags."--config" = "${pkgs.writeTextDir "kitty.conf" ''
          font_family JetBrains Mono
          font_size 12
          hide_window_decorations yes
          tab_bar_style powerline
          tab_powerline_style round
          background_opacity 0.6
          sync_to_monitor yes
          confirm_os_window_close 0
          cursor_shape beam
          cursor_trail 1
          cursor_trail_decay 0.1 0.6
          map ctrl+, send_text all \x1b[44;5u
          map ctrl+. send_text all \x1b[46;5u
          map ctrl+; send_text all \x1b[59;5u
          map ctrl+' send_text all \x1b[39;5u
          map ctrl+/ send_text all \x1b[47;5u
          map ctrl+minus send_text all \x1b[45;5u
          map ctrl+equal send_text all \x1b[61;5u
          map ctrl+grave_accent send_text all \x1b[96;5u
          map ctrl+shift+left send_text all \x1b[1;6D
          map ctrl+shift+right send_text all \x1b[1;6C
          map shift+enter send_text all \x1b[13;2u
        ''}/kitty.conf";
      };
    };
}
