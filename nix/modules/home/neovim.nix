{ dotfiles, ... }: {
  # AstroNvim + Lazy.nvim manage all plugins themselves.
  # Nix just places the config directory and ensures the neovim binary exists.
  xdg.configFile."nvim" = {
    source    = "${dotfiles}/nvim";
    recursive = true;
  };

  programs.neovim = {
    enable        = true;
    defaultEditor = true;
  };
}
