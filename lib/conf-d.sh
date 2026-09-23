# shellcheck shell=bash
# Source every drop-in in ~/.config/hopper/conf.d/*.sh, in lexical order (so a
# numeric prefix sets it: 50-foo.sh runs before 60-bar.sh). Cross-shell.
#
# This is how other repos extend the shell without hopper knowing about them:
# each one leaves a symlink here (bin/hopper-link) pointing at a script inside
# itself. Contract for a drop-in:
#   - it is sourced, not executed, in bash and in zsh
#   - $__hopper_dropin_dir is the directory of the *resolved* file, so the
#     drop-in can find its own repo without guessing
#   - it may use anything hopper defines (__hopper_ask_flag, _mtime, _sha256,
#     __HOPPER_REPO_STATUS, __HOPPER_RANDOM_EMOJI)
#   - a dangling link (repo deleted) is skipped silently
#
# Requires $__hopper_dir.

__hopper_confd="${XDG_CONFIG_HOME:-$HOME/.config}/hopper/conf.d"

if [[ -d $__hopper_confd ]]; then
    # zsh errors on a glob with no matches; bash would leave it literal
    if [ -n "$ZSH_VERSION" ]; then
        setopt null_glob
    else
        shopt -s nullglob
    fi
    for __hopper_dropin in "$__hopper_confd"/*.sh; do
        [[ -r $__hopper_dropin ]] || continue
        __hopper_dropin_dir=$(dirname "$(realpath "$__hopper_dropin")")
        source "$__hopper_dropin"
    done
    if [ -n "$ZSH_VERSION" ]; then
        unsetopt null_glob
    else
        shopt -u nullglob
    fi
    unset __hopper_dropin __hopper_dropin_dir
fi
unset __hopper_confd
