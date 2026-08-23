# agent-jail

A jail for terminal coding agents — [Claude Code](https://claude.com/claude-code),
[OpenAI Codex CLI](https://developers.openai.com/codex/cli), and
[OpenCode](https://opencode.ai) — a minimal container with only what the agents
need to read, build, test, and commit code. Not a human dev environment: no
shells, editors, or quality-of-life tooling.

The repo you point it at is the only project filesystem the container can see.
Each agent's profile/state directory is mounted so logins and sessions survive;
no other home-directory files are exposed.

One shared image holds all three CLIs; the launcher picks which agent to boot.

## Usage

```bash
./build.sh                                    # one-time build (re-run after Dockerfile changes)
./claude-sbx ~/code/some-repo                 # Claude Code session, skip-permissions on
./codex-sbx  ~/code/some-repo                 # Codex session, approvals+sandbox bypassed
./opencode-sbx ~/code/some-repo               # OpenCode session, permissions skipped

# Session resume (mapped per agent):
./claude-sbx   <repo> --resume                # Claude's session picker
./claude-sbx   <repo> --continue              # latest Claude session in this repo
./codex-sbx    <repo> --resume                # Codex's session picker (`codex resume`)
./codex-sbx    <repo> --continue              # `codex resume --last`
./opencode-sbx <repo> --continue              # `-c`, continue last session
./opencode-sbx <repo> --resume <session-id>   # `-s <id>` (no launch-time picker)

./claude-sbx   <repo> --legacy-resume         # choose an old /workspace Claude session
./codex-sbx    <repo> bash                    # override: get a shell instead of the agent
```

The repo defaults to the current directory. Any leading option is forwarded to
the agent (`--resume`/`--continue` are translated per-agent); a non-option
command replaces the default entirely — that is the shell escape hatch.

The `.zshrc` aliases `claude`, `codex`, and `opencode` to these launchers, so
typing e.g. `opencode` anywhere on the host drops you into the jailed version.

## What's inside

git, ripgrep, the build toolchain (make/cmake/ninja/build-essential),
python3 + uv, curl/wget/unzip/jq, openssh-client, usbutils,
Node.js + all three agent CLIs.

## What it mounts

| Host | Container | Mode | Purpose |
|------|-----------|------|---------|
| the repo dir       | same absolute path    | rw | project files and stable session identity |
| `~/.claude`        | `/root/.claude`       | rw | claude: credentials, settings, transcripts |
| `~/.claude.json`   | `/root/.claude.json`  | rw | claude: account, onboarding, per-project state |
| `~/.codex`         | `/root/.codex`        | rw | codex: auth.json, config.toml, sessions |
| `~/.config/opencode`     | `/root/.config/opencode`      | rw | opencode: opencode.json config |
| `~/.local/share/opencode` | `/root/.local/share/opencode` | rw | opencode: auth.json, sessions, snapshots |
| `$SSH_AUTH_SOCK`   | `/tmp/ssh-agent.sock` | ro | SSH forwarding for git push/pull (no key in container) |
| `/dev/bus/usb`     | `/dev/bus/usb`        | rw | host USB devices (hotplug-aware; host udev permissions apply) |

Only the mounts for the agent being launched are applied. Git identity is passed
as `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars pulled from your host `git
config`, so agents can commit without mounting your `.gitconfig`.

### Session identity

Sessions are tied to the absolute working-directory path for all three agents.
The repo is therefore mounted at its original host path inside the container,
not renamed to a shared `/workspace`: host and sandbox runs share the same
project identity, and different repos never mix histories. Normal startup
creates a new session; use the resume flags above (or the in-app commands) to
reopen one. Resuming appends to the existing conversation.

Claude-only: sessions made by an older launcher were recorded as `/workspace`.
Use `claude-sbx <repo> --legacy-resume` to mount at `/workspace` for one run.
Preview carefully so you pick a transcript belonging to the supplied repo.

## Working alongside the agent (live pair-programming)

The repo is a **bind mount**, not a copy — the container operates on your actual
directory, sharing the same files and the same `.git`. You can keep editing and
committing on the host while the agent works inside the container:

| While the container runs… | …the other side sees it |
|---|---|
| you edit a file on the host        | the agent sees it on its next read — no restart |
| the agent edits/creates a file     | appears on the host instantly, **owned by you** |
| the agent commits inside the container | your host `git log` shows it immediately |
| you commit on the host             | the container sees it on its next `git` call |

**Worth knowing:**

- **Same-file simultaneous edits are last-write-wins** — let one side own a
  file at a time; git is your safety net.
- **Repo and profile mounts persist; the container doesn't.** The container is
  `--rm` and ephemeral: apt installs and other changes outside those mounts
  vanish on exit.
- **Build artifacts land on your host too.** If the agent runs `npm install` /
  `uv sync`, `node_modules` / `.venv` get written into your repo dir. Fine when
  host and container share a platform (both Linux x86-64 here).

## How isolation & ownership work

The container runs as **root**, which in *rootless* podman maps to your
unprivileged host user. So files written to the repo stay owned by you, and
container-root holds zero privilege on the host.

> **Note:** this uses root-in-rootless rather than a `dev` user with
> `--userns=keep-id`, because keep-id fails on hosts using the native `overlay`
> storage driver (`OCI permission denied opening merged`). `IS_SANDBOX=1` (set
> by the launcher) is what lets Claude's skip-permissions mode run as root;
> codex/opencode ignore it.

## Security boundary

The container can read and write the selected repo plus the launched agent's
profile directory. That profile contains credentials and all locally stored
session transcripts — not only those for the selected repo. The forwarded SSH
agent can authorize signatures even though no private key is copied into the
container. Host USB devices are exposed too (`/dev/bus/usb` bind-mounted, with
your device-group memberships carried in), so the agent can talk to anything
you can — SDRs, serial adapters, security keys included.

These mounts are what make account and session reuse possible, but they are not
protected from a malicious instruction in a repository. Because the container
also needs network access to reach model APIs, run this launcher only on
repositories you trust. In particular, container-side changes to profile
settings, plugins, or hooks persist on the host and may be loaded by a later
host-side run of the same agent; avoid running host and sandbox instances of
the *same* agent concurrently against its shared profile. Anthropic's
[development-container guidance](https://code.claude.com/docs/en/devcontainer)
describes the same credential-exposure tradeoff.

## Requirements

Rootless [podman](https://podman.io/). Tested with podman 5.4.

## Adding another agent

Add a case to the per-agent wiring block in `agent-jail` (container-name prefix,
default command with bypass flag, state dirs/files, mounts), add a thin wrapper
script if you want an `<agent>-sbx` entry point, and add the CLI to the npm
install line in the Dockerfile.
