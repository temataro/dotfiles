# ─── claude-sandbox/Dockerfile ───────────────────────────────────────────────
# A jail for Claude Code — NOT a human dev environment.
# Only what Claude needs to read, build, test, and commit code. No shells,
# editors, or quality-of-life tooling for humans.
#
# Build:  ./build.sh
# Launch: claude-sbx [path/to/repo]
# ─────────────────────────────────────────────────────────────────────────────

FROM docker.io/library/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── What Claude needs ─────────────────────────────────────────────────────────
#   git ............... branch/commit/status/diff
#   ripgrep ........... Claude Code's internal code search
#   build toolchain ... compile & run tests to verify its own work
#   python + uv ....... Python repos
#   curl/wget/unzip/jq  general build & fetch utilities
#   openssh-client .... git over SSH
# bash ships in the base image (Claude Code shells out to it for subprocesses).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    ripgrep \
    make cmake ninja-build build-essential \
    python3 python3-pip python3-venv \
    curl wget unzip jq \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js LTS + Claude Code ─────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @anthropic-ai/claude-code

# ── uv (system-wide via UV_INSTALL_DIR) ───────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# ── Run as root ───────────────────────────────────────────────────────────────
# In ROOTLESS podman the container's root (uid 0) maps to your unprivileged host
# user, so files written to the bind-mounted repo come out owned by YOU and
# container-root holds zero host privilege. (A `dev` user + --userns=keep-id was
# tried first but keep-id can't reach native rootless-overlay mounts on this host:
# "OCI permission denied opening merged". Root-in-rootless is the clean fix.)
# Fallback for running the image directly. The launcher overrides this with the
# repo's original absolute path so Claude's per-directory session key matches
# the same checkout when it is used outside the container.
WORKDIR /workspace

# ── Entry banner ──────────────────────────────────────────────────────────────
# Flashes a "you're in the sandbox" screen for ~1s, then clears and runs the
# real command. Wraps everything (Claude or a shell override) via ENTRYPOINT.
COPY sbx-entry /usr/local/bin/sbx-entry
RUN chmod +x /usr/local/bin/sbx-entry
ENTRYPOINT ["/usr/local/bin/sbx-entry"]

# Boot straight into a Claude Code session. The container is the filesystem
# permission boundary; IS_SANDBOX=1 (set by the launcher) lets skip-permissions
# run as root. Override with e.g. `claude-sbx <repo> bash` for a shell.
CMD ["claude", "--dangerously-skip-permissions"]
