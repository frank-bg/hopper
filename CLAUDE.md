# CLAUDE.md

hopper is a **public** repo: a portable bash/zsh shell layer that also gets cloned on
servers that are not mine. See README.md for what it does.

## Rules

- **No references to anything private.** No hostnames, IPs, tailnet names, private repo
  names, employer names or paths under someone's home. hopper does not know which repos
  extend it. If a feature needs private knowledge, it belongs in a drop-in inside the
  private repo, not here.
- **Cross-shell, cross-userland.** Everything in `lib/` is sourced by both bash and zsh,
  on Linux and on macOS (bash 3.2, BSD `stat`/`sed`/`date`). Put new platform differences
  in `lib/compat.sh`. Use POSIX ERE with `[[:space:]]` in sed (never `\s`), and remember
  that zsh arrays start at 1.
- **Login is quiet.** Code that runs when the shell starts prints nothing unless it needs
  an answer (a one-time `__hopper_ask_flag`) or there is something to act on.
- **Never overwrite user config.** A git setting is written only when it is unset (or
  when it points at a file that no longer exists). The one exception is an opt-in
  toggle that asks for it explicitly: `hopper.perRepoIdentity` strips any global
  identity on every shell start.
- Naming: functions and globals use the `__hopper_` / `__HOPPER_` prefix, and git config
  toggles live under `hopper.*`.

## Drop-in contract

`lib/conf-d.sh` sources `~/.config/hopper/conf.d/*.sh` in lexical order, after hopper's
own setup and before `__hopper_check_repos`. It sets `$__hopper_dropin_dir` for each
drop-in and skips dangling links. Treat this contract as a public API: other repos
depend on it.

## Commits

Format: `<type>(<scope>): <imperative description>`, with type one of feat, fix,
refactor, chore, config or docs. At most 72 characters and no trailing period.
