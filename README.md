# hopper

A portable shell layer for bash and zsh, on Linux and macOS. It carries the prompt,
git aliases, a handful of helpers and the terminal configs I want on every machine I
log into, my own or somebody else's.

Named after Grace Hopper, who spent her career bringing the machine closer to the
person using it.

## Install

```bash
git clone --recurse-submodules https://github.com/frank-bg/hopper.git ~/hopper

# bash (Debian/Ubuntu/Mint source ~/.bash_aliases from the stock ~/.bashrc)
ln -s ~/hopper/.bash_aliases ~/
# anywhere else:  echo 'source ~/hopper/.bash_aliases' >> ~/.bashrc

# zsh
echo 'source ~/hopper/.zsh_aliases' >> ~/.zshrc
```

To update, run `hpull` (it pulls and refreshes the submodule).

## What you get

- **Prompt**: date, `user@host`, the cwd, git status via
  [posh-git-sh](https://github.com/lyze/posh-git-sh), and a random emoji (animals by
  default, see `hopper.emoji` below). It runs
  with `GIT_OPTIONAL_LOCKS=0`, so it never takes `index.lock` in the middle of a rebase
- **Git**: the aliases `git lg`, `git s` and `git pfl`, plus a global excludes file
  (`global.gitignore`). A setting is written only when it is unset, so hopper never
  overwrites your own config
- **Helpers**:
  - `ahi-fue` pings an ntfy.sh topic when a long command finishes (`make build;
    ahi-fue`). Secrets in the command are redacted before it is sent
  - `wttr`, `bye` and `..`
  - `hpull` updates hopper
- **Repo status at login**: `git status` for hopper, `~/projects/*` and any paths listed
  in `.repo_status_sources` (gitignored, one per line). It runs `git fetch` at most once
  every 12 h per repo and checks each repo at most once an hour, showing it only when it
  is dirty, ahead or behind its upstream
- **Composer**: optionally adds the global bin dir to the PATH and loads completion
  (you are asked once)
- **Terminal configs**: kitty (`~/.config/kitty` is symlinked here when a display is
  present; per-host settings go in `config/kitty/local.conf`, which is gitignored) and
  zellij (`ZELLIJ_CONFIG_DIR`, with `ez` to attach to the `main` session).
  `install-zellij` installs or updates zellij in `~/.local/bin` from its latest GitHub
  release (Linux x86_64/aarch64, macOS arm64/x86_64)
- **`sudo -A` without a TTY**: `SUDO_ASKPASS` points to `bin/sudo-askpass`, which
  shows a zenity dialog on Linux or an osascript one on macOS, and fails on headless
  hosts

Feature toggles are asked once per host and stored in global git config under
`hopper.*`. One of them, `hopper.perRepoIdentity`, makes git identity per repo only:
it sets `user.useConfigOnly` and removes any global `user.*`/`author.*`/`committer.*`
on every shell start, so a repo without its own identity refuses to commit.

The prompt emoji is set with `hopper.emoji`, which is never asked (unset means
animals). Name a set (`animals`, `fruits`, `hearts`, `monkeys`, `moons`, `vehicles`,
`clocks`, `sports`, `books`, `globes`, `faces`), give your own space-separated list, or
turn it off. It is read when the shell starts, so a change applies to the next one:

```bash
git config --global hopper.emoji moons
git config --global hopper.emoji "🦀 🐙 🦑"
git config --global hopper.emoji off
```

## Extending it: drop-ins

hopper has no knowledge of other repos. Instead, anything that wants to add to the
shell leaves a script in `~/.config/hopper/conf.d/`, and hopper sources every `*.sh`
there in lexical order after its own setup:

```bash
hopper-link 50-work ~/work-repo/shell/hopper.sh   # link (idempotent)
hopper-link --list                                # what is linked, and where to
hopper-link --remove 50-work
hopper-link --prune                               # drop links whose repo is gone
```

A drop-in is sourced in both bash and zsh, so write it for both. It can use:

- `$__hopper_dropin_dir`, the directory of its resolved file, to find its own repo
- `__hopper_ask_flag <key> <question>`, a y/n toggle stored in git config
- `__HOPPER_REPO_STATUS <dir>`, to add its repo to the login status
- `_mtime` and `_sha256`, the GNU/BSD shims

A link whose repo has been deleted is skipped silently. Deleting a private repo from a
machine therefore needs no other cleanup.

## Portability

Everything under `lib/` runs on bash and zsh, on GNU and BSD userlands (including
macOS's bash 3.2 and BSD `stat`/`sed`). `lib/compat.sh` holds the shims. New code
should not assume GNU coreutils.
