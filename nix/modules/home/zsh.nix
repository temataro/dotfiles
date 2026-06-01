{ pkgs, dotfiles, ... }: {
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable  = true;
      theme   = "ys";
      plugins = [ "git" ];
    };

    history.stamps = "dd/mm/yyyy";

    # These must be set before Oh My Zsh is sourced.
    localVariables = {
      CASE_SENSITIVE              = "true";
      COMPLETION_WAITING_DOTS     = "true";
      DISABLE_UNTRACKED_FILES_DIRTY = "true";
      DISABLE_MAGIC_FUNCTIONS     = "true";
      DISABLE_LS_COLORS           = "true";
    };

    sessionVariables = {
      LANG         = "en_US.UTF-8";
      ARCHFLAGS    = "-arch x86_64";
      EDITOR       = "vim";
      QUARTUS_ROOT = "$HOME/intelFPGA_lite/20.1/quartus";
      CUDA_ROOT    = "/usr/local/cuda";
    };

    initExtra = ''
      # PATH additions — toolchain roots
      export PATH="$QUARTUS_ROOT/bin:$CUDA_ROOT/bin:$PATH"
      export PATH="$PATH:/home/Code/fpga_playground/icesugar/tools"
      export PATH="/home/tem/.opencode/bin:$PATH"

      # Auto-attach to tmux for interactive shells
      if command -v tmux >/dev/null 2>&1 && [[ -z "$TMUX" ]] && [[ -t 0 ]]; then
        tmux
      fi

      # Scroll screen before clearing so scrollback stays visible
      scroll-and-clear-screen() {
        printf '\n%.0s' {1..$LINES}
        zle clear-screen
      }
      zle -N scroll-and-clear-screen
      bindkey '^l' scroll-and-clear-screen

      # Open current command buffer in $EDITOR
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^x^e' edit-command-line

      # ── Git helpers ──────────────────────────────────────────────────────
      gitwip() { git commit -m "WIP: $*"; }

      gitgreet() {
        if command -v onefetch >/dev/null 2>&1; then onefetch
        else echo "onefetch not installed"; fi
      }

      # ── Python virtualenv: walk up to nearest .venv ──────────────────────
      src() {
        local d=$PWD
        while :; do
          if [[ -f "$d/.venv/bin/activate" ]]; then
            . "$d/.venv/bin/activate"
            [[ -n "$VIRTUAL_ENV" ]] && echo "Activated: $VIRTUAL_ENV" \
                                    || echo "Activated: $d/.venv"
            return 0
          fi
          [[ "$d" = "$HOME" || "$d" = "/" ]] && break
          d=''${d:h}
        done
        echo "No .venv found from $PWD up to ~"; return 1
      }

      mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

      # Quote-of-the-day — path resolved into the nix store at build time
      progq() { ${pkgs.python3}/bin/python3 ${dotfiles}/extra/lews-therin/humming.py; }
      progq
    '';

    shellAliases = {
      # Listing
      ls    = "ls -lhat --color";
      ll    = "ls -alF --color";
      la    = "ls -lha --color";
      l     = "ls -CF --color";
      sl    = "ls --color";
      hh    = "ls -lhat | head -n 6";
      gls   = "git ls-files | xargs ls -lhat --color=auto";
      hat   = "eza --group-directories-first -al --sort newest";

      # Typos / convenience
      c     = "clear";
      clera = "clear";
      celar = "clear";
      sduo  = "sudo";
      szsh  = "source ~/.zshrc";

      # Tools  (bat is `bat` on NixOS, not `batcat` as on Debian)
      lgg    = "lazygit";
      vim    = "nvim";
      vi     = "/usr/bin/vim";
      brf    = "bladeRF-cli";
      grc    = "gnuradio-companion";
      tmd    = "tmux detach";
      tma    = "tmux attach";
      open   = "xdg-open";
      quarto = "/opt/quarto/bin/quarto";
      docker = "podman";
      zpool  = "sudo zpool";
      zfs    = "sudo zfs";
      gits   = "git status --column=always,nodense,auto";
      grep   = "rg";
      cat    = "bat";
      rm     = "rm -i";

      # Watch helpers
      wf   = "watch -n 0.1 -d";
      wfls = "watch -n 0.1 -d ls -lhat";

      yt-dlp = "yt-dlp --list-formats";
    };
  };

  programs.zoxide = {
    enable             = true;
    enableZshIntegration = true;
  };
}
