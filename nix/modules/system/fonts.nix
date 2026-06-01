{ pkgs, ... }: {
  fonts = {
    enableDefaultPackages = true;

    # Nerd Fonts used across the terminal stack and Neovim.
    # In nixpkgs ≥ 24.11 individual fonts live under pkgs.nerd-fonts.<name>.
    # If you're on an older nixpkgs, replace with:
    #   (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ... ]; })
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono    # primary coding font
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.space-mono
      nerd-fonts.m-plus
      nerd-fonts.meslo-lg
      nerd-fonts.share-tech-mono

      # SFMono is a proprietary Apple font — not redistributable in nixpkgs.
      # Install manually from a macOS system, or use JetBrainsMono as a substitute
      # and update font-family in ghostty/config and kitty.conf accordingly.
    ];

    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" "monospace" ];
      sansSerif = [ "DejaVu Sans" ];
      serif     = [ "DejaVu Serif" ];
    };
  };
}
