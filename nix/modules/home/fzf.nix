{ ... }: {
  # Note: programs.fzf.enable installs fzf and wires the zsh keybindings/completion,
  # so the bare `fzf` entry in packages.nix is redundant (harmless to leave).
  programs.fzf = {
    enable               = true;
    enableZshIntegration = true;

    # ── Sensible default UI ──────────────────────────────────────────────────
    # --height keeps fzf in the bottom 40% instead of taking the whole terminal
    # (it renders inline rather than switching to the alternate screen).
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
    ];

    # Use fd for listing: respects .gitignore, includes hidden files, skips .git.
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    # CTRL-T (paste a file path) — same lister, with a bat preview pane.
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || cat {}'"
    ];

    # ALT-C (cd into a dir) — directory lister with a tree preview.
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} 2>/dev/null | head -100'"
    ];
  };

  # `ff [query]` — fuzzy-find a file (with preview) and open the selection in
  # the editor on Enter. This is the "press Enter → go to the file" workflow.
  # It's a dedicated function rather than a global bind, so CTRL-R history search
  # and the ALT-C cd widget keep their normal Enter behavior.
  programs.zsh.initExtra = ''
    ff() {
      local file
      file=$(fd --type f --hidden --follow --exclude .git \
        | fzf --query="''${1:-}" --select-1 --exit-0 \
              --preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || cat {}') \
        && nvim "$file"
    }
  '';
}
