{ pkgs, ... }: {
  # GUI applications and desktop-shell utilities.
  # Unfree entries (discord) require allowUnfree — set in hosts/nixos/default.nix
  # for NixOS, or via NIXPKGS_ALLOW_UNFREE / allowUnfreePredicate for standalone HM.
  home.packages = with pkgs; [
    # ── Communication ────────────────────────────────────────────────────────
    discord
    telegram-desktop

    # ── Media ────────────────────────────────────────────────────────────────
    vlc
    haruna          # Qt/mpv video player
    qbittorrent

    # ── Files / disks ────────────────────────────────────────────────────────
    kdePackages.dolphin
    gnome-disk-utility      # was AUR nautilus-gnome-disks
    qpdf

    # ── Screenshots ──────────────────────────────────────────────────────────
    flameshot               # config in app-configs.nix
    kdePackages.spectacle

    # ── Launchers / notifications ────────────────────────────────────────────
    rofi-wayland            # config in app-configs.nix
    dunst                   # notification daemon (Arch config dir was empty)

    # ── Hardware / flashing ──────────────────────────────────────────────────
    rpi-imager
    # etcher — packaged as pkgs.etcher but frequently marked insecure/unmaintained.
    # Enable deliberately if you still need it:
    # etcher

    # ── VPN ──────────────────────────────────────────────────────────────────
    protonvpn-gui           # proton-vpn-gtk-app

    # ── 3D printing ──────────────────────────────────────────────────────────
    # Chosen: native package (drop the com.prusa3d.PrusaSlicer flatpak).
    # Remove the flatpak on Arch with: flatpak uninstall com.prusa3d.PrusaSlicer
    prusa-slicer

    # ── Windows compatibility ────────────────────────────────────────────────
    wineWowPackages.stable
  ];
}
