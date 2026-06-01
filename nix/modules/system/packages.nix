{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Core CLI
    git
    curl
    wget
    unzip
    zip
    file
    pciutils
    usbutils

    # Editors
    vim
    neovim

    # Build tools
    gnumake
    gcc
    clang

    # Scripting
    python3
    lua

    # System tools
    htop
    btop

    # Wayland
    wl-clipboard
  ];

  # Make zsh the default system shell (users still need shell = pkgs.zsh in their account)
  programs.zsh.enable = true;

  # Rootless containers; `docker` command maps to podman via dockerCompat
  virtualisation.podman = {
    enable       = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
