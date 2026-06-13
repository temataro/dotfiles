{ pkgs, dotfiles, ... }: {
  imports = [
    ./modules/home/git.nix
    ./modules/home/zsh.nix
    ./modules/home/tmux.nix
    ./modules/home/neovim.nix
    ./modules/home/terminals.nix
    ./modules/home/chromium.nix
    ./modules/home/app-configs.nix
    ./modules/home/packages.nix
    ./modules/home/desktop.nix
    ./modules/home/dev.nix
    ./modules/home/wm/i3.nix
    ./modules/home/wm/hyprland.nix
  ];

  home.username      = "tem";
  home.homeDirectory = "/home/tem";

  # Bump this in lockstep with each NixOS / HM release upgrade.
  home.stateVersion  = "24.11";

  programs.home-manager.enable = true;
}
