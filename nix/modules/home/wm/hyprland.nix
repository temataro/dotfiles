{ pkgs, inputs, dotfiles, ... }: {
  # Enable the Hyprland home-manager module so it wires up the systemd user
  # session, desktop entry, and environment variables — even though we drop
  # the raw config in via extraConfig rather than the declarative settings attrset.
  wayland.windowManager.hyprland = {
    enable  = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    # Raw config; migrate to `settings = { ... }` attrset over time if desired.
    extraConfig = builtins.readFile "${dotfiles}/hyprland-configs/hypr/hyprland.conf";
  };

  # Waybar, swaylock, hyprpaper configs
  xdg.configFile = {
    "waybar/config".source       = "${dotfiles}/hyprland-configs/waybar/config";
    "waybar/style.css".source    = "${dotfiles}/hyprland-configs/waybar/style.css";
    "swaylock/config".source     = "${dotfiles}/hyprland-configs/swaylock/config";
    "hypr/hyprpaper.conf".source = "${dotfiles}/hyprland-configs/hypr/hyprpaper.conf";
  };

  home.packages = with pkgs; [
    hyprpaper
    swaylock-effects
    wofi
    waybar
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    networkmanagerapplet
  ];
}
