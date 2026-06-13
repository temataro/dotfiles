{ dotfiles, ... }: {
  # Raw-copied configs for tools that were configured on the Arch machine but
  # not yet declared in Nix. Sources live under nix/config/ in this repo.
  # Each can be upgraded to a native Home Manager module (programs.starship,
  # programs.btop, etc.) later if you want fully structured settings.
  xdg.configFile = {
    # Shell prompt. Not wired into zsh shell-init: the active prompt is
    # Oh My Zsh's "ys" theme (see zsh.nix). This just preserves the config so
    # starship is ready if you switch. To activate, enable programs.starship.
    "starship.toml".source = "${dotfiles}/nix/config/starship.toml";

    # rofi launcher (theme reference patched for NixOS — see the file)
    "rofi/config.rasi".source = "${dotfiles}/nix/config/rofi/config.rasi";

    # btop system monitor (runtime btop.log and themes/ deliberately excluded)
    "btop/btop.conf".source = "${dotfiles}/nix/config/btop/btop.conf";

    # glow markdown renderer
    "glow/glow.yml".source = "${dotfiles}/nix/config/glow/glow.yml";

    # flameshot screenshot tool. NOTE: savePath is the absolute
    # /home/tem/Pictures/Screenshots — ensure that directory exists.
    "flameshot/flameshot.ini".source = "${dotfiles}/nix/config/flameshot/flameshot.ini";
  };
}
