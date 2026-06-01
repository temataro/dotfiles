{ pkgs, ... }: {
  home.packages = with pkgs; [
    # ── Shell / CLI essentials ───────────────────────────────────────────────
    ripgrep      # grep = rg
    bat          # cat = bat  (binary is `bat` on NixOS, not `batcat`)
    eza          # hat alias (exa successor)
    fzf
    fd
    zoxide       # smart cd (also wired in zsh.nix)
    jq
    tree

    # ── Git tools ────────────────────────────────────────────────────────────
    git-lfs
    lazygit
    onefetch     # gitgreet helper

    # ── Terminal emulators ───────────────────────────────────────────────────
    ghostty
    kitty
    alacritty

    # ── System monitoring ────────────────────────────────────────────────────
    btop
    htop

    # ── Media ────────────────────────────────────────────────────────────────
    yt-dlp
    vlc
    playerctl    # media key daemon

    # ── Container / virtualisation ───────────────────────────────────────────
    podman
    podman-compose

    # ── Python toolchain ─────────────────────────────────────────────────────
    python3
    uv           # fast pip/venv replacement

    # ── Other languages ──────────────────────────────────────────────────────
    rustup
    go

    # ── Neovim support tools ─────────────────────────────────────────────────
    stylua       # Lua formatter
    lua-language-server

    # ── X utilities ─────────────────────────────────────────────────────────
    xclip
    xdg-utils
    arandr       # xrandr GUI

    # ── Wayland utilities ────────────────────────────────────────────────────
    wl-clipboard
    grim
    slurp
    swappy
    waybar
    hyprpaper
    swaylock-effects
    wofi
    networkmanagerapplet  # nm-applet system-tray icon

    # ── Misc ─────────────────────────────────────────────────────────────────
    cowsay
    unzip
    wget
    curl
  ];
}
