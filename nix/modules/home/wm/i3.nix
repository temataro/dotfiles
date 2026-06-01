{ pkgs, dotfiles, ... }: {
  # Raw config copy — the i3 config is already well-tuned; no declarative
  # translation needed. The system-level module (display.nix) enables i3 in X11.

  xdg.configFile."i3/config" = {
    source = "${dotfiles}/config";
  };

  xdg.configFile."i3status/config" = {
    source = "${dotfiles}/.i3status.conf";
  };

  home.packages = with pkgs; [
    i3
    i3status
    i3lock-fancy
    picom          # compositor (shadows, transparency)
    feh            # wallpaper setter
    rofi           # app launcher
    dunst          # notification daemon
    xss-lock       # screen-lock on suspend
    brightnessctl
    arandr         # monitor layout GUI
    xdotool
  ];
}
