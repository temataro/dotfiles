{ pkgs, ... }: {
  # System services that on Arch were just installed packages, but on NixOS are
  # expressed as options. Mapped from pacman: flatpak, cronie, zram-generator,
  # smartmontools, blueman, polkit-kde-agent, plex-media-server.

  services.flatpak.enable = true;   # you use the PrusaSlicer/Firefox flatpaks

  services.cron.enable = true;      # cronie

  zramSwap.enable = true;           # zram-generator

  services.smartd.enable = true;    # smartmontools (disk SMART monitoring)

  # Bluetooth + applet
  hardware.bluetooth.enable = true;
  services.blueman.enable   = true;

  # Polkit authentication agent (KDE) — start it in your WM autostart too.
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.kdePackages.polkit-kde-agent-1 ];

  # Plex media server (was AUR plex-media-server). Unfree.
  # Runs as the `plex` user with state in dataDir (default /var/lib/plex).
  # IMPORTANT: enabling the service installs the *server*, not your library or
  # account login. To carry those over, copy the Arch server's
  # "Plex Media Server" Application Support dir into this dataDir at cutover
  # (see nix/MIGRATION.md). The machine identity + auth token live there.
  services.plex = {
    enable  = true;
    openFirewall = true;
    # dataDir = "/var/lib/plex";   # default; override if you migrate elsewhere
  };
}
