#!/usr/bin/env bash
# desnap_ubuntu.sh — replace Ubuntu's snap apps with native builds for fast
# cold starts (snap firefox/chromium/nvim launch seconds slower than native).
# Written for the S5606CA on Ubuntu 25.04; generic enough for any recent Ubuntu.
#
# Run as your normal user (it sudo-prompts once):  bash extra/desnap_ubuntu.sh
# Close Firefox/Chromium/Telegram/Thunderbird first — profiles get copied.
#
# Per-app and fail-soft: a failure (dead PPA, no network) skips that app and
# keeps its snap. Safe to re-run; already-migrated apps are skipped.
# Profile policy: the snap profile is treated as the live one; a pre-existing
# native profile dir is backed up to <dir>.pre-desnap.bak first.

set -u
SUMMARY=()
say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { SUMMARY+=("OK      $*"); }
skip() { SUMMARY+=("SKIPPED $*"); printf '\033[1m!! %s\033[0m\n' "$*" >&2; }

[ "$(id -u)" -eq 0 ] && { echo "Run as your user, not root/sudo."; exit 1; }
sudo -v || exit 1
have_snap() { snap list "$1" >/dev/null 2>&1; }

# migrate_profile <snap-src-dir> <dst-parent> <dst-name>
migrate_profile() {
  local src=$1 parent=$2 name=$3 dst=$2/$3
  [ -d "$src" ] || { echo "   (no snap profile at $src — nothing to migrate)"; return 0; }
  if [ -e "$dst" ]; then
    rm -rf "$dst.pre-desnap.bak"
    mv "$dst" "$dst.pre-desnap.bak"
    echo "   (existing $dst backed up to $dst.pre-desnap.bak)"
  fi
  mkdir -p "$parent"
  rsync -a "$src/" "$dst/"
}

############################ firefox -> Mozilla apt ###########################
if have_snap firefox; then
  say "firefox: snap -> Mozilla apt repo"
  sudo install -d -m 0755 /etc/apt/keyrings
  if wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg \
       | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null \
     && [ -s /etc/apt/keyrings/packages.mozilla.org.asc ]; then
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
      | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
      | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
    sudo apt-get update -qq
    if sudo apt-get install -y firefox \
       && ! dpkg-query -W -f='${Version}' firefox 2>/dev/null | grep -q snap; then
      migrate_profile "$HOME/snap/firefox/common/.mozilla/firefox" "$HOME/.mozilla" firefox
      sudo snap remove firefox && ok "firefox: native deb, profile migrated"
    else skip "firefox: Mozilla deb didn't install — snap kept"; fi
  else skip "firefox: couldn't fetch Mozilla signing key — snap kept"; fi
fi

######################## thunderbird -> mozillateam PPA #######################
if have_snap thunderbird; then
  say "thunderbird: snap -> mozillateam PPA"
  if sudo add-apt-repository -y ppa:mozillateam/ppa >/dev/null 2>&1; then
    printf 'Package: thunderbird*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1000\n' \
      | sudo tee /etc/apt/preferences.d/mozillateam-thunderbird >/dev/null
    sudo apt-get update -qq
    if sudo apt-get install -y thunderbird \
       && ! dpkg-query -W -f='${Version}' thunderbird 2>/dev/null | grep -q snap; then
      migrate_profile "$HOME/snap/thunderbird/common/.thunderbird" "$HOME" .thunderbird
      sudo snap remove thunderbird && ok "thunderbird: native deb, profile migrated"
    else skip "thunderbird: PPA deb didn't install (snap wrapper or missing) — snap kept"; fi
  else skip "thunderbird: mozillateam PPA unavailable — snap kept"; fi
fi

########################## chromium -> xtradeb PPA ############################
if have_snap chromium; then
  say "chromium: snap -> xtradeb PPA (native build)"
  if sudo add-apt-repository -y ppa:xtradeb/apps >/dev/null 2>&1; then
    sudo apt-get update -qq
    if sudo apt-get install -y chromium \
       && ! dpkg-query -W -f='${Version}' chromium 2>/dev/null | grep -q snap; then
      migrate_profile "$HOME/snap/chromium/common/chromium" "$HOME/.config" chromium
      sudo snap remove chromium && ok "chromium: native deb, profile migrated"
    else skip "chromium: xtradeb deb didn't install — snap kept (alt: google-chrome .deb)"; fi
  else skip "chromium: xtradeb PPA unavailable — snap kept (alt: google-chrome .deb)"; fi
fi

########################### nvim -> upstream tarball ##########################
if have_snap nvim; then
  say "nvim: snap -> upstream tarball in /opt/nvim"
  if wget -qO /tmp/nvim-desnap.tar.gz \
       https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
    sudo rm -rf /opt/nvim && sudo mkdir -p /opt/nvim
    if sudo tar -xzf /tmp/nvim-desnap.tar.gz -C /opt/nvim --strip-components=1; then
      sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
      sudo snap remove nvim
      ok "nvim: $(/usr/local/bin/nvim --version | head -1) at /usr/local/bin/nvim (config untouched)"
    else skip "nvim: tarball extract failed — snap kept"; fi
  else skip "nvim: download failed — snap kept"; fi
fi

################# telegram -> official tarball (user-local) ###################
# User-local so Telegram's built-in self-updater can write to its own dir.
if have_snap telegram-desktop; then
  say "telegram: snap -> official tarball (self-updating, user-local)"
  if wget -qO /tmp/tsetup-desnap.tar.xz https://telegram.org/dl/desktop/linux; then
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin" "$HOME/.local/share/applications"
    rm -rf "$HOME/.local/opt/Telegram"
    if tar -xJf /tmp/tsetup-desnap.tar.xz -C "$HOME/.local/opt"; then
      ln -sf "$HOME/.local/opt/Telegram/Telegram" "$HOME/.local/bin/telegram-desktop"
      cat > "$HOME/.local/share/applications/telegram-desktop.desktop" <<EOF
[Desktop Entry]
Name=Telegram
Exec=$HOME/.local/opt/Telegram/Telegram -- %u
Icon=telegram
Type=Application
Categories=Network;InstantMessaging;
MimeType=x-scheme-handler/tg;
EOF
      TGSRC=""
      for base in current common; do
        d="$HOME/snap/telegram-desktop/$base/.local/share/TelegramDesktop"
        [ -d "$d" ] && TGSRC=$d && break
      done
      if [ -n "$TGSRC" ]; then
        migrate_profile "$TGSRC" "$HOME/.local/share" TelegramDesktop
      else
        echo "   (no snap session data found — just log in again)"
      fi
      sudo snap remove telegram-desktop && ok "telegram: user-local, self-updates in place"
    else skip "telegram: extract failed — snap kept"; fi
  else skip "telegram: download failed — snap kept"; fi
fi

################################## summary ####################################
say "summary"
printf '   %s\n' "${SUMMARY[@]:-nothing to do — no target snaps installed}"
echo
echo "Remaining snaps (infra + anything skipped):"
snap list 2>/dev/null | awk 'NR>1{print "   " $1}'
echo
echo "Optional: the ghostty snap is still installed but kitty is the terminal:"
echo "   sudo snap remove ghostty"
echo "Note: a running shell may have the old nvim path hashed — 'hash -r' or a"
echo "new terminal picks up /usr/local/bin/nvim."
