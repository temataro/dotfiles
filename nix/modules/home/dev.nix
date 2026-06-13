{ pkgs, ... }:
let
  # Python with the scientific/util libraries that were installed via pacman.
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    ipython
    numpy
    scipy
    sympy
    matplotlib
    pyyaml
    mako
    openpyxl
    pytest
    simplejson
    intervaltree
    parse
    # ordered-set, json5 → available as ps.ordered-set / ps.json5 if needed
  ]);
in {
  home.packages = with pkgs; [
    # ── Python ───────────────────────────────────────────────────────────────
    pythonEnv
    pypy3
    uv             # also in packages.nix; harmless duplicate, kept for clarity

    # ── C / C++ ──────────────────────────────────────────────────────────────
    clang
    gdb
    ninja
    # gcc, gnumake are in system/packages.nix

    # ── Other languages ──────────────────────────────────────────────────────
    rustup
    go
    jdk            # jre-openjdk-headless
    antlr4
    nodejs         # for @openai/codex etc. (install codex via npm or nodePackages)

    # ── Embedded toolchains ──────────────────────────────────────────────────
    gcc-arm-embedded    # arm-none-eabi-{gcc,binutils,newlib}
    openocd
    libftdi1
    # RISC-V cross GCC — uncomment if you build for riscv:
    # pkgsCross.riscv64-embedded.buildPackages.gcc
    # probe-rs tooling (was cargo-installed probe-rs/cargo-embed/cargo-flash):
    # probe-rs-tools

    # ── HDL / FPGA ───────────────────────────────────────────────────────────
    iverilog
    yosys
    gtkwave

    # ── EDA ──────────────────────────────────────────────────────────────────
    kicad          # bundles symbol/footprint/3d libraries

    # ── SDR ──────────────────────────────────────────────────────────────────
    gnuradio
    volk           # libvolk
    soapysdr
    soapyrtlsdr    # was AUR soapyrtlsdr-git

    # ── Numerical / docs / viz ───────────────────────────────────────────────
    octave
    tectonic       # LaTeX engine
    graphviz
    xdot

    # ── GPU compute (unfree, large — enable deliberately) ─────────────────────
    # cudatoolkit
    # cudaPackages.nsight_systems
    # (opencv with CUDA: opencv.override { enableCuda = true; })
  ];
}
