{ pkgs, inputs, ... }: {
  # ── X11 (i3) ────────────────────────────────────────────────────────────────
  services.xserver = {
    enable = true;

    xkb = {
      layout  = "us";
      options = "ctrl:nocaps";   # Caps Lock → Ctrl
    };

    windowManager.i3 = {
      enable  = true;
      package = pkgs.i3;
    };

    displayManager.lightdm.enable = true;
  };

  # ── Wayland / Hyprland ───────────────────────────────────────────────────────
  programs.hyprland = {
    enable          = true;
    package         = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  # XDG portal — needed for screen sharing, file pickers, etc.
  xdg.portal = {
    enable       = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
