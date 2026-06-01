{ ... }: {
  programs.git = {
    enable    = true;
    userName  = "Temesgen Ataro";
    userEmail = "atarotemesgen@gmail.com";

    aliases = {
      lol  = "log --decorate --pretty=oneline --abbrev-commit";
      lool = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      lop  = "log -p --decorate";
      lof  = "log -p --follow --decorate";
      g    = "grep --break --heading --line-number";
      gi   = "grep --break --heading --line-number --ignore-case";
      vee  = "log --decorate --cherry-mark --oneline --graph --boundary";
      dh   = "diff HEAD";
      rhh  = "reset --hard HEAD";
      rc   = "rebase --continue";
      ca   = "commit --amend";
      can  = "commit --amend --no-edit";
    };

    extraConfig = {
      push.default         = "upstream";
      pull.rebase          = true;
      init.defaultBranch   = "main";

      core = {
        excludesFile = "~/.gitignore_global";
        editor       = "vim";
        abbrev       = 12;
      };

      merge = {
        conflictstyle = "diff3";
        summary       = true;
      };

      color = {
        ui          = "auto";
        branch      = "auto";
        diff        = "auto";
        interactive = "auto";
        status      = "auto";
      };

      "color.diff-highlight" = {
        oldNormal    = "red bold";
        oldHighlight = "red bold 52";
        newNormal    = "green bold";
        newHighlight = "green bold 22";
      };

      "color.diff" = {
        meta       = "11";
        frag       = "magenta bold";
        func       = "146 bold";
        commit     = "yellow bold";
        old        = "red bold";
        new        = "green bold";
        whitespace = "red reverse";
      };

      pretty.fixes = ''Fixes: %h ("%s")'';

      status.submoduleSummary = true;

      sendemail = {
        name         = "Temesgen Ataro";
        chainreplyto = false;
      };

      # Prefer SSH for all GitHub traffic
      "url.ssh://git@github.com/".insteadOf = "https://github.com/";

      "filter.lfs" = {
        smudge   = "git-lfs smudge -- %f";
        process  = "git-lfs filter-process";
        required = true;
        clean    = "git-lfs clean -- %f";
      };
    };
  };
}
