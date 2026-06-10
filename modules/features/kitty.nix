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
        ''}/kitty.conf";
      };
    };
}
