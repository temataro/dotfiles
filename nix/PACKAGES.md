# Package Inventory & Nix Mapping

Snapshot of user-installed packages on the Arch machine (`pacman -Qqen`, `-Qqem`,
cargo, npm) sorted by category, with how each maps into this Nix config.

**Disposition legend**
- **pkg** — declared as a package (see the module named)
- **option** — expressed as a NixOS/HM *option*, not a package
- **done** — already handled before this pass
- **skip** — Arch/AUR-specific, no Nix equivalent needed
- **note** — needs a manual decision / non-trivial nixpkgs attr

---

## Shell & CLI tools  → `modules/home/packages.nix`
| Package | Nix | Disposition |
|---|---|---|
| bat, eza, fzf, fd, ripgrep, zoxide, jq, tree, ncdu | same | pkg (done) |
| less, lsof, rsync, wget, curl, usbutils | same | pkg |
| glow | `glow` + config | pkg, config in `app-configs.nix` |
| visidata | `visidata` | pkg |
| wiki-tui *(cargo)* | `wiki-tui` | pkg |
| onefetch | `onefetch` | pkg (done) |
| starship | `starship` + config | pkg, config in `app-configs.nix` |
| btop, htop | same | pkg (done); btop config in `app-configs.nix` |
| zsh, tmux, neovim, vim, git, git-lfs, lazygit | — | done |

## Terminals  → `modules/home/terminals.nix`
| Package | Disposition |
|---|---|
| kitty, ghostty, alacritty | done (configs ported) |

## Desktop apps  → `modules/home/desktop.nix`
| Package | Nix attr | Disposition |
|---|---|---|
| discord | `discord` | pkg (unfree) |
| telegram-desktop | `telegram-desktop` | pkg |
| vlc | `vlc` | pkg |
| haruna | `haruna` | pkg |
| qbittorrent | `qbittorrent` | pkg |
| dolphin | `kdePackages.dolphin` | pkg |
| nautilus-gnome-disks *(AUR)* | `gnome-disk-utility` | pkg |
| spectacle | `kdePackages.spectacle` | pkg |
| flameshot | `flameshot` + config | pkg, config in `app-configs.nix` |
| rpi-imager | `rpi-imager` | pkg |
| balena-etcher *(AUR)* | `etcher` | note (often flagged insecure/unmaintained) |
| proton-vpn-gtk-app | `protonvpn-gui` | pkg |
| prusa-slicer | `prusa-slicer` | pkg (also installed as flatpak — dedupe) |
| qpdf | `qpdf` | pkg |
| yt-dlp, playerctl | same | pkg (done) |

## Window manager / desktop shell
| Package | Nix | Disposition |
|---|---|---|
| hyprland, hyprpaper, waybar, swaylock, wofi, grim, slurp, swappy | — | done |
| i3-wm, i3status, i3lock, i3blocks | `i3`, `i3status`, `i3lock`, `i3blocks` | done / `wm/i3.nix` |
| rofi | `rofi-wayland` | pkg + config (`app-configs.nix`) |
| dunst | `dunst` | pkg (`desktop.nix`); existing config dir was empty |
| picom, feh | same | done (`wm/i3.nix`) |
| flameshot, spectacle | — | see Desktop apps |
| brightnessctl, network-manager-applet | same | done |
| blueman | `blueman` | **option** `services.blueman` + `hardware.bluetooth` (`system/services.nix`) |
| polkit-kde-agent | `kdePackages.polkit-kde-agent-1` | option (`system/services.nix`) |
| uwsm | `uwsm` | **option** `programs.uwsm.enable` |
| qt5-wayland, qt6-wayland | — | pulled in by Hyprland/Qt; option |

## Editors / browsers
| Package | Disposition |
|---|---|
| neovim, vim, nano | done / core |
| chromium | done (`chromium.nix`) |
| firefox-i18n-de | note — Firefox itself is a **flatpak** here (`org.mozilla.firefox`). Use `programs.firefox` if you want it native. |

## Languages & dev toolchain  → `modules/home/dev.nix`
| Package | Nix attr | Disposition |
|---|---|---|
| clang, gcc, gdb, ninja, gnumake | same | pkg (gcc/make in `system/packages.nix`) |
| perf | `linuxPackages.perf` | note |
| python-{scipy,sympy,yaml,mako,openpyxl,pytest,simplejson,json5,intervaltree,parse,ordered-set}, ipython, python-pip, python-virtualenv, python-build, python-installer | `python3.withPackages` | pkg |
| pypy3 | `pypy3` | pkg |
| uv | `uv` | pkg (done) |
| rustup *(cargo toolchain)* | `rustup` | pkg (done) |
| go | `go` | pkg (done) |
| jre-openjdk-headless | `jdk` | pkg |
| antlr4, antlr4-runtime | `antlr4` | pkg |
| @openai/codex, node-gyp *(npm)* | `nodejs`, `codex` | note — codex via `nodePackages`/npm |

## Embedded / FPGA / EDA  → `modules/home/dev.nix`
| Package | Nix attr | Disposition |
|---|---|---|
| arm-none-eabi-gcc/binutils/newlib | `gcc-arm-embedded` | pkg |
| riscv64-linux-gnu-gcc | `pkgsCross.riscv64-embedded.buildPackages.gcc` | note (cross set) |
| openocd | `openocd` | pkg |
| libftdi | `libftdi1` | pkg |
| probe-rs, cargo-embed, cargo-flash, probe-run, elf2uf2-rs *(cargo)* | `probe-rs-tools` | note |
| iverilog | `iverilog` | pkg |
| yosys | `yosys` | pkg |
| gtkwave | `gtkwave` | pkg |
| kicad, kicad-library, kicad-library-3d | `kicad` | pkg (bundles libraries) |
| gnuradio | `gnuradio` | pkg (config dir `~/.config/gnuradio` not ported — regenerated) |
| libvolk | `volk` | pkg |
| soapyrtlsdr-git *(AUR)* | `soapyrtlsdr` + `soapysdr` | pkg |
| octave | `octave` | pkg (trivial `octave-gui.ini` not ported) |
| tectonic | `tectonic` | pkg |
| graphviz, xdot | `graphviz`, `xdot` | pkg |

## GPU / CUDA  → `modules/system/hardware.nix` + `dev.nix`
| Package | Nix | Disposition |
|---|---|---|
| nvidia-open-dkms, nvidia-settings | `hardware.nvidia` (open modules) | option |
| libva-nvidia-driver | `hardware.graphics.extraPackages` | option |
| cuda | `cudatoolkit` | note (unfree, large) |
| opencv-cuda | `opencv.override { enableCuda = true; }` | note |
| nsight-systems | `cudaPackages.nsight_systems` | note |

## System / base  → `modules/system/*`
| Package | Nix option | Module |
|---|---|---|
| linux, linux-headers, linux-firmware | `boot.kernelPackages` | `boot.nix` (done) |
| amd-ucode | `hardware.cpu.amd.updateMicrocode` | `hardware.nix` |
| networkmanager, iwd | `networking.networkmanager` (iwd backend) | `networking.nix` (done) |
| gdm | `services.xserver.displayManager.gdm` | `display.nix` (currently lightdm — switch if desired) |
| xorg-server, xorg-xinit | `services.xserver.enable` | `display.nix` (done) |
| flatpak | `services.flatpak.enable` | `system/services.nix` |
| cronie | `services.cron.enable` | `system/services.nix` |
| zram-generator | `zramSwap.enable` | `system/services.nix` |
| reflector | — | skip (Arch mirror tool; Nix uses substituters) |
| smartmontools | `services.smartd` | `system/services.nix` |
| efibootmgr, dkms, base, base-devel, man-db, man-pages | — | provided by NixOS defaults |
| qbittorrent/etc tray, xdg-utils | — | done |

## Media server  → `modules/system/services.nix`
| Package | Nix | Disposition |
|---|---|---|
| plex-media-server *(AUR)* | `services.plex.enable` | option |

## Gaming / compat
| Package | Nix | Disposition |
|---|---|---|
| wine | `wineWowPackages.stable` | pkg (`desktop.nix`) |

## No Nix equivalent (skip)
| Package | Why |
|---|---|
| yay-bin, yay-bin-debug | AUR helper — Nix uses nixpkgs/flakes, no AUR |
| reflector | Arch mirror ranking — N/A |
| dnslookup-bin *(AUR)* | `dnslookup` exists in nixpkgs if wanted (pkg) |

---

### Notable findings & decisions
1. **PrusaSlicer** — was installed twice (pacman + flatpak). **Decision: keep the
   native `prusa-slicer` package**, drop the flatpak (`flatpak uninstall
   com.prusa3d.PrusaSlicer`).
2. **CUDA stack** (cuda, opencv-cuda, nsight) — **Decision: left out.** Install
   separately on NixOS later via `cudatoolkit` / `cudaPackages.*` when needed.
   nvidia-open driver itself is still configured in `system/hardware.nix`.
3. **Plex** — **Decision: enabled** as a NixOS service (`services.plex`) in
   `system/services.nix`. Activates only on real NixOS; library + login are
   migrated state, see `MIGRATION.md`.
4. **Firefox is a flatpak**, not a native package (only `firefox-i18n-de` locale
   is in pacman). Decide native vs flatpak at cutover.
5. **rustup/cargo** manages its own toolchain + several cargo binaries (probe-rs,
   wiki-tui, elf2uf2-rs). On Nix prefer packaged equivalents; keep `rustup` for
   ad-hoc toolchains.
6. **gnuradio/octave/dunst** had config dirs that were empty or machine-generated;
   not ported (regenerated on first run).

> **Layer note:** NixOS *services* (Plex, flatpak, bluetooth, nvidia, zram) only
> run under NixOS — not via Nix on Arch. On Arch, standalone Home Manager can
> install **user packages + dotfiles** only. App **logins/data are not packages**
> and are migrated as state — see `MIGRATION.md`.
