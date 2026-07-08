# claude-sandbox

A jail for [Claude Code](https://claude.com/claude-code) — a minimal container with
only what Claude needs to read, build, test, and commit code. Not a human dev
environment: no shells, editors, or quality-of-life tooling.

The repo you point it at is the only project filesystem the container can see.
Claude's profile is also mounted so your login and local sessions survive;
no other home-directory files are exposed.

## Usage

```bash
./build.sh                              # one-time build (re-run after Dockerfile changes)
./claude-sbx ~/code/some-repo           # start a new session; repo defaults to cwd
./claude-sbx ~/code/some-repo --resume  # choose a saved session for this repo
./claude-sbx ~/code/some-repo --continue # resume this repo's latest session
./claude-sbx ~/code/some-repo --legacy-resume # choose an old /workspace session
./claude-sbx ~/code/some-repo bash      # override: get a shell instead of Claude
```

`claude-sbx` drops you straight into a Claude Code session running with
`--dangerously-skip-permissions`. The container is the filesystem permission
boundary; see [Security boundary](#security-boundary) for what remains exposed.

## Account and session persistence

Claude stores credentials and transcripts under `~/.claude`, but keeps account,
onboarding, and per-project state in the sibling `~/.claude.json`. The launcher
mounts both paths read-write, so after you have logged in once it opens directly
into that same account instead of repeating setup.

Sessions are tied to the absolute working-directory path. The repo is therefore
mounted at its original host path inside the container, not renamed to a shared
`/workspace`. Host and sandbox runs now use the same project identity, and
different repos no longer mix their histories.

Normal startup creates a new session. Pass `--resume` to open the picker,
`--continue` to reopen the latest session in this directory, or run `/resume`
from inside Claude. Resuming appends to the existing conversation. See Claude's
[session documentation](https://code.claude.com/docs/en/sessions) for picker and
branching options.

Sessions made by an older version of this launcher were all recorded as
`/workspace`. They are not auto-migrated because that path mixed every repo
together. Use `--legacy-resume` to mount the selected repo at `/workspace` for
one run and open that legacy picker. Preview carefully so you choose a transcript
that belongs to the repo you supplied.

## What's inside

git, ripgrep, the build toolchain (make/cmake/ninja/build-essential),
python3 + uv, curl/wget/unzip/jq, openssh-client, and Node.js + Claude Code.

## What it mounts

| Host | Container | Mode | Purpose |
|------|-----------|------|---------|
| the repo dir       | same absolute path    | rw | project files and stable session identity |
| `~/.claude`        | `/root/.claude`       | rw | credentials, settings, and session transcripts |
| `~/.claude.json`   | `/root/.claude.json`  | rw | account, onboarding, and per-project state |
| `$SSH_AUTH_SOCK`   | `/tmp/ssh-agent.sock` | ro | SSH forwarding for git push/pull (no key in container) |

Git identity is passed as `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars pulled from
your host `git config`, so Claude can commit without mounting your `.gitconfig`.

## Working alongside Claude (live pair-programming)

The repo is a **bind mount**, not a copy — the container operates on your actual
directory, sharing the same files and the same `.git`. So you can keep editing
and committing on the host while Claude works inside the container, exactly like
a normal agentic pair-programming session. Changes flow both ways in real time,
with no sync step:

| While the container runs… | …the other side sees it |
|---|---|
| you edit a file on the host        | Claude sees it on its next read — no restart |
| Claude edits/creates a file        | appears on the host instantly, **owned by you** |
| Claude commits inside the container | your host `git log` shows the commit immediately |
| you commit on the host             | the container sees it on its next `git` call |

Typical flow: run `claude-sbx ~/code/myrepo` in one terminal, and keep using your
own editor and terminals on the host as usual.

**Worth knowing:**

- **Same-file simultaneous edits are last-write-wins** — just like two people
  typing in one file. Let one side own a file at a time; git is your safety net.
- **The repo and Claude profile mounts persist.** The container is `--rm` and
  ephemeral: apt installs and other changes outside those mounts vanish on exit.
- **Build artifacts land on your host too.** If Claude runs `npm install` /
  `uv sync`, `node_modules` / `.venv` get written into your repo dir. Fine when
  host and container share a platform (both Linux x86-64 here).

## How isolation & ownership work

The container runs as **root**, which in *rootless* podman maps to your
unprivileged host user. So files Claude writes to the repo stay owned by you,
and container-root holds zero privilege on the host.

> **Note:** this uses root-in-rootless rather than a `dev` user with
> `--userns=keep-id`, because keep-id fails on hosts using the native `overlay`
> storage driver (`OCI permission denied opening merged`). `IS_SANDBOX=1` (set by
> the launcher) is what lets Claude's skip-permissions run as root.

## Security boundary

The container can read and write the selected repo, `~/.claude`, and
`~/.claude.json`. That profile contains your Claude credentials and all locally
stored Claude session transcripts, not only those for the selected repo. The
forwarded SSH agent can also authorize signatures even though the private key is
not copied into the container.

These mounts are what make account and session reuse possible, but they are not
protected from a malicious instruction in a repository. Because the container
also needs network access to reach Claude, run this launcher only on repositories
you trust. In particular, container-side changes to profile settings, plugins,
or hooks persist on the host and may be loaded by a later host-side Claude run;
avoid running host and sandbox Claude concurrently against this shared profile.
Anthropic's
[development-container guidance](https://code.claude.com/docs/en/devcontainer)
describes the same credential-exposure tradeoff.

## Requirements

Rootless [podman](https://podman.io/). Tested with podman 5.4.
