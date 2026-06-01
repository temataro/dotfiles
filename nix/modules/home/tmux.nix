{ pkgs, lib, ... }:
let
  # Plugins not yet in nixpkgs — build them from GitHub.
  # Fill in the correct sha256 by running:
  #   nix-prefetch-github <owner> <repo> --rev <rev>
  tmux-ip-address = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-ip-address";
    version    = "unstable-2022-09-08";
    src = pkgs.fetchFromGitHub {
      owner  = "anghootys";
      repo   = "tmux-ip-address";
      rev    = "3ce9e7b9609b81a36c8b71a77a61bf8c6aff8be5";
      sha256 = lib.fakeSha256;
    };
  };

  tmux-pomodoro = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-pomodoro";
    version    = "unstable-2023-01-01";
    src = pkgs.fetchFromGitHub {
      owner  = "swaroopch";
      repo   = "tmux-pomodoro";
      rev    = "master";
      sha256 = lib.fakeSha256;
    };
  };
in {
  programs.tmux = {
    enable          = true;
    prefix          = "C-a";
    keyMode         = "vi";
    historyLimit    = 40000;
    baseIndex       = 1;
    mouse           = true;
    aggressiveResize = true;
    escapeTime      = 0;
    focusEvents     = true;
    terminal        = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible

      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "macchiato"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_current_background "#{@thm_lavender}"
          set -g @catppuccin_pane_status_enabled "yes"
          set -g @catppuccin_pane_border_status "off"
          set -g @catppuccin_pane_left_separator "█"
          set -g @catppuccin_pane_right_separator "█"
          set -g @catppuccin_pane_middle_separator "█"
          set -g @catppuccin_pane_number_position "left"
          set -g @catppuccin_pane_default_fill "number"
          set -g @catppuccin_pane_default_text "#W"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_pane_border_style "fg=#{@thm_overlay_0}"
          set -g @catppuccin_pane_active_border_style "#{?pane_in_mode,fg=#{@thm_lavender},#{?pane_synchronized,fg=#{@thm_magenta},fg=#{@thm_lavender}}}"
          set -g @catppuccin_pane_color "#{@thm_green}"
          set -g @catppuccin_pane_background_color "#{@thm_surface_0}"
        '';
      }

      cpu
      tmux-ip-address
      tmux-pomodoro
    ];

    extraConfig = ''
      # Pane indexing from 1 (baseIndex covers windows)
      setw -g pane-base-index 1

      # Window / session management
      set -g allow-rename on
      set -g renumber-windows on
      set -g set-titles on
      setw -g monitor-activity on
      set -g bell-action any
      set -g visual-bell off
      set -g visual-activity off
      set -g detach-on-destroy off

      # True-color + undercurl support
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
      set -as terminal-features ",*:RGB"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Status bar
      set -g status-interval 1
      set-option -g status-left-length 100
      set-option -g status-right-length 100
      set-option -g status-style "fg=#828bb1 bg=default"
      set-option -g window-status-format "#{window_index}:#{window_name}  "
      set-option -g window-status-current-format "#{window_index}:#{window_name}"
      set-option -g window-status-activity-style none
      set -g status-left '#[fg=green]#H #[fg=black]• #[fg=green,bright]#(uname -r | cut -c 1-6) #[default]'
      set -g status-right '#[fg=#81a1a1,bg=default]#{ram_icon} #{cpu_temp_fg_color}cpu_temp: #{cpu_temp_icon}#{cpu_temp}  ipv4:#[fg=#81ffa1,bg=default]#{ip_address}  #[fg=white,bg=default]%a %l:%M:%S'

      # ── Key bindings ──────────────────────────────────────────────────────
      bind C-a send-prefix

      unbind r
      bind r source-file ~/.config/tmux/tmux.conf\; display-message "config reloaded"

      bind C-p previous-window
      bind C-n next-window

      # Vim-style pane navigation (with neovim split awareness)
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind -r C-h select-window -t :-
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      # C-l is surrendered to the shell (scroll-and-clear-screen in zsh)
      bind -n C-l send-keys 'C-l'

      bind -r n next-window
      bind -r p previous-window

      bind H resize-pane -L 5
      bind L resize-pane -R 5
      bind J resize-pane -D 5
      bind K resize-pane -U 5
      bind -r C-H resize-pane -L 7
      bind -r C-J resize-pane -D 5
      bind -r C-K resize-pane -U 5

      bind -r N run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) + 1)"
      bind -r P run-shell "tmux swap-window -t $(expr $(tmux list-windows | grep \"(active)\" | cut -d \":\" -f 1) - 1)"

      bind Space last-window
      bind b switch-client -l
      bind-key B break-pane -d
      bind-key E command-prompt -p "join pane from: " "join-pane -h -s '%%'"
      bind-key y run -b "tmux show-buffer | xclip -selection clipboard"\; display-message "copied to clipboard"
      bind-key g new-window -n lazygit -c "#{pane_current_path}" "lazygit"
      bind-key o command-prompt -p "open app: " "new-window '%%'"
      bind-key X command-prompt -p "kill window: " "kill-window -t '%%'"

      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind C-e display-popup -E "\
          tmux list-sessions -F '#{?session_attached,,#{session_name}}' |\
          sed '/^$/d' |\
          fzf --reverse --header jump-to-session |\
          xargs tmux switch-client -t"
    '';
  };
}
