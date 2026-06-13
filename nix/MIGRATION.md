# Arch → NixOS State Migration ("login and all")

The Nix config reproduces **packages and configuration**. It does **not** carry
your **state**: account logins, server identities, keys, histories, media
libraries. Those are directories you copy at cutover. This is the checklist for
that copy, with the real paths/sizes found on the Arch machine.

> Golden rule: **packages are declarative (rebuilt), state is data (copied).**
> Installing a package never restores its login — the token/library lives in the
> state dir below.

---

## 0. Before you wipe Arch — make a backup

Copy these onto an external drive or the new disk **with permissions preserved**.
Use `rsync -aHAX` (or `tar -cpf`) so ownership/ACLs/mode bits survive — this
matters for `.ssh`, `.gnupg`, Plex, and NetworkManager.

```sh
# user-owned state → external drive
rsync -aHAX --info=progress2 \
  ~/.ssh ~/.gnupg ~/.zsh_history ~/.mozilla \
  ~/.config/chromium ~/.config/qBittorrent ~/.local/share/qBittorrent \
  ~/.config/kicad ~/.config/gnuradio ~/.gnuradio ~/.wine \
  ~/.local/share/TelegramDesktop ~/.config/discord ~/.config/Proton \
  ~/Pictures \
  /mnt/backup/home-tem/

# root-owned state → needs sudo
sudo rsync -aHAX /etc/NetworkManager/system-connections/ /mnt/backup/nm-connections/
sudo rsync -aHAX /var/lib/plex/                          /mnt/backup/plex/
```

---

## 1. Critical — keys & secrets (copy exactly, fix perms)

| What | Path | Size | Notes |
|---|---|---|---|
| SSH keys/config | `~/.ssh` | 24K | must be `700` dir, `600` keys |
| GPG keyring | `~/.gnupg` | 120K | must be `700`; restores signing/encryption identity |
| Wi-Fi passwords | `/etc/NetworkManager/system-connections/` | (root) | files are `600 root:root`, contain PSKs |

```sh
# after restoring on NixOS:
chmod 700 ~/.ssh ~/.gnupg
chmod 600 ~/.ssh/* 2>/dev/null
sudo chmod 600 /etc/NetworkManager/system-connections/*
sudo chown root:root /etc/NetworkManager/system-connections/*
```

NetworkManager connections also work declaratively if you'd rather not copy
secrets around — but copying is the fastest "wifi just works" path.

---

## 2. Plex — the server identity + library (your "plex login")

- **Arch:** runs as user `plex`, data in `/var/lib/plex` (the
  `Library/Application Support/Plex Media Server/` subtree holds the server
  machine identity, **auth token / account claim**, watch state, and the
  library database).
- **NixOS:** `services.plex.enable = true` is already set; default `dataDir`
  is `/var/lib/plex`, also running as user `plex`.

```sh
# on NixOS, with plex service stopped:
sudo systemctl stop plex
sudo rsync -aHAX /mnt/backup/plex/  /var/lib/plex/
sudo chown -R plex:plex /var/lib/plex     # ownership is what makes the login "stick"
sudo systemctl start plex
```

If the server doesn't recognize itself, sign in once and re-claim at
`https://plex.tv/claim` — the library DB is preserved regardless.

> Note the `plex` user's UID may differ between Arch and NixOS; that's why the
> `chown -R plex:plex` step (by name, not number) is essential.

---

## 3. Browsers (large — your chromium profile is 2.0G)

| Browser | Path | Size | Notes |
|---|---|---|---|
| Chromium | `~/.config/chromium` | 2.0G | full profile: logins, cookies, history, extension data. Copy whole dir. |
| Firefox (native) | `~/.mozilla` | 16K | nearly empty — barely used. |
| Firefox (flatpak) | `~/.var/app/org.mozilla.firefox/` | — | no profile found; was unused. |

Alternative to copying 2G: sign into Chrome/Google sync and let it repopulate.
The declarative `chromium.nix` reinstalls the *extensions*; their settings come
from this profile or from sync.

---

## 4. Apps — copy vs just re-login

**Copy (has meaningful local data):**

| App | Path | Size |
|---|---|---|
| qBittorrent settings | `~/.config/qBittorrent` | 32K |
| qBittorrent resume/torrents | `~/.local/share/qBittorrent` | 9.9M |
| Telegram | `~/.local/share/TelegramDesktop` | 232M |
| KiCad prefs/libs | `~/.config/kicad` | 580K |
| GnuRadio prefs | `~/.config/gnuradio` + `~/.gnuradio` | 52K |
| Wine prefix | `~/.wine` | 1.3G |
| Pictures (incl. screenshots) | `~/Pictures` | 13G |

**Easier to just re-login (token-based; copying is fiddly):**
- **Discord** (`~/.config/discord`, 34M) — re-login is simpler than migrating its leveldb token.
- **Proton VPN** (`~/.config/Proton`) — re-authenticate in the app.

---

## 5. Shell history & misc

| What | Path |
|---|---|
| Zsh history | `~/.zsh_history` (408K) |
| User crontab | none set on Arch (`crontab -l` empty) — nothing to migrate |
| `~/.gitconfig` | already declarative (`modules/home/git.nix`) — don't copy |

---

## 6. Recommended cutover order

1. **Backup** everything in §0 to external media (verify the copy before wiping).
2. Install NixOS; generate `hardware-configuration.nix` and drop it into
   `nix/hosts/nixos/`.
3. `nixos-rebuild switch --flake .#nixos` → packages + services come up.
4. Restore **keys/wifi** (§1), then log in / connect.
5. Restore **Plex** state (§2) and `chown` it.
6. Restore **browser + app** state (§3, §4) into your home dir.
7. Re-login the token apps (Discord, Proton VPN).
8. Sanity-check, then retire the Arch disk.

---

## What is NOT migrated (regenerated automatically)

- Package binaries — rebuilt by Nix.
- Caches: `~/.cache`, browser caches, `~/.config/btop/btop.log`, shader caches.
- Neovim plugins — Lazy re-installs on first launch.
- Anything in `/nix/store` — content-addressed, rebuilt.
