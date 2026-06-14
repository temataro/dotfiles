{ dotfiles, ... }: {
  # Raw file copies — these configs are large and stable; no nix translation needed.
  # Switch to programs.ghostty / programs.kitty for fully declarative management later.

  xdg.configFile."ghostty/config" = {
    source = "${dotfiles}/ghostty/config";
  };

  xdg.configFile."kitty/kitty.conf" = {
    source = "${dotfiles}/kitty.conf";
  };
}
