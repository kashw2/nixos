{ self, inputs, ... }:
{
  flake.wrappers.tmux =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.modules.default ];
      config = {
        package = pkgs.tmux;
        flags."-f" =
          let
            wcolor = pkgs.writeShellScript "tmux-window-color" ''
              n="$1"; [ -z "$n" ] && n=0
              n=$(( n % 7 ))
              printf '#%s' "$(printf %s "F9E2AF A6E3A1 89B4FA F38BA8 CBA6F7 94E2D5 FAB387" | ${lib.getExe' pkgs.coreutils "cut"} -d' ' -f$(( n + 1 )))"
            '';
          in
          pkgs.writeText "tmux.conf" ''
            set -g default-terminal "tmux-256color"
            set -g prefix C-a
            unbind C-b
            bind C-a send-prefix
            set -s escape-time 0
            set -g mouse on
            set -g history-limit 50000
            setw -g mode-keys vi

            set -ga terminal-overrides ",*256col*:Tc"
            set -g allow-passthrough on
            set -s extended-keys always
            set -sa terminal-features "xterm*:extkeys"
            set -g focus-events on
            set -g base-index 1
            set -g pane-base-index 1
            set -g renumber-windows on

            bind -T copy-mode-vi v send -X begin-selection
            bind -T copy-mode-vi y send -X copy-pipe-and-cancel '${lib.getExe' pkgs.wl-clipboard "wl-copy"}'

            set -g status on
            set -g status-position bottom
            set -g status-justify left
            set -g status-interval 5
            set -g status-style "bg=#0B0B14,fg=#CDD6F4"
            set -g status-left-length 60
            set -g status-right-length 200

            set -g status-left "#[fg=#0B0B14,bg=#CBA6F7,bold]#{?client_prefix,#[bg=#FAB387],} #S "

            set -g window-status-separator " "
            set -g window-status-format "#[fg=#(${wcolor} #{window_index}),bg=#0B0B14]   #I #W "
            set -g window-status-current-format "#[fg=#(${wcolor} #{window_index}),bg=#0B0B14,bold] ● #I #W #[default]"
            setw -g window-status-activity-style "fg=#F9E2AF,bg=#0B0B14,none"

            set -g status-right "#[fg=#94E2D5,bg=#0B0B14]#[fg=#0B0B14,bg=#94E2D5] #(${lib.getExe' pkgs.coreutils "cut"} -d' ' -f1 /proc/loadavg) #[fg=#10101A,bg=#94E2D5]#[fg=#CDD6F4,bg=#10101A] #H #[fg=#CBA6F7,bg=#10101A]#[fg=#0B0B14,bg=#CBA6F7,bold] %Y-%m-%d #[fg=#89B4FA,bg=#CBA6F7]#[fg=#0B0B14,bg=#89B4FA,bold] %H:%M "

            set -g pane-border-style "fg=#10101A"
            set -g pane-active-border-style "fg=#CBA6F7"
            set -g message-style "bg=#10101A,fg=#CDD6F4"
            set -g message-command-style "bg=#10101A,fg=#CDD6F4"
            set -g mode-style "bg=#CBA6F7,fg=#0B0B14"

            bind -n C-S-Left previous-window
            bind -n C-S-Right next-window

            bind -n '`' switch-client -T backtick
            bind -T backtick '`' send-keys '`'
            bind -T backtick 1 select-window -t :1
            bind -T backtick 2 select-window -t :2
            bind -T backtick 3 select-window -t :3
            bind -T backtick 4 select-window -t :4
            bind -T backtick 5 select-window -t :5
            bind -T backtick 6 select-window -t :6
            bind -T backtick 7 select-window -t :7
            bind -T backtick 8 select-window -t :8
            bind -T backtick 9 select-window -t :9
            bind -T backtick 0 select-window -t :10

            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            unbind '"'
            unbind %

            bind C-t run-shell '${
              lib.getExe' inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default "workmux"
            } sidebar'

            run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
            set -g @resurrect-dir '/home/keanu/.local/share/tmux/resurrect'
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
            run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
          '';
      };
    };
}
