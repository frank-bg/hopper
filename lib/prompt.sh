# shellcheck shell=bash
# Prompt wiring — cross-shell (bash + zsh).
# Renders: terminal title (bash), date, user@host, cwd in colors, git status
# (via posh-git-sh), then a random animal emoji and the prompt char.
#
# Requires:
#   - $__hopper_dir  (set by the entrypoint that sources this file)
#   - __HOPPER_RANDOM_EMOJI  (from lib/emoji.sh, sourced earlier)
#   - $MYPS1  (bash only; terminal-title escape set by the entrypoint)

# Load posh-git-sh if the submodule is present; otherwise install a minimal shim
# so the prompt still works (without git status) instead of erroring out.
if [ -f "$__hopper_dir/modules/posh-git-sh/git-prompt.sh" ]; then
    . "$__hopper_dir/modules/posh-git-sh/git-prompt.sh"
fi
type __posh_git_ps1 >/dev/null 2>&1 || __posh_git_ps1() { PS1="$1$2"; }

if [ -n "$ZSH_VERSION" ]; then
    # zsh prompt escapes: %F{color}/%f color, %B/%b bold, %n@%m user@host,
    # %~ cwd, %# prompt char. date is baked in at precmd time via $(date).
    __HOPPER_PROMPT() {
        # Call directly (not via $(...)): a subshell would re-seed $RANDOM to a
        # fixed value, freezing the emoji. This runs in the current shell and
        # leaves the pick in $__HOPPER_EMOJI.
        __HOPPER_RANDOM_EMOJI >/dev/null
        # Scoped to the call, not exported to the shell: the prompt's git
        # status must never take index.lock and collide with a rebase.
        GIT_OPTIONAL_LOCKS=0 __posh_git_ps1 \
            "$(date)"$'\n'"%F{green}%n@%m %F{yellow}%~ " \
            " %B%F{blue}"$'\n\n'" $__HOPPER_EMOJI %# %f%b "
    }
    if autoload -Uz add-zsh-hook 2>/dev/null; then
        add-zsh-hook precmd __HOPPER_PROMPT
    else
        precmd_functions+=(__HOPPER_PROMPT)
    fi
elif [ -n "$BASH_VERSION" ]; then
    # GIT_OPTIONAL_LOCKS=0 scoped to the call (see the zsh branch above).
    PROMPT_COMMAND='GIT_OPTIONAL_LOCKS=0 __posh_git_ps1 "$MYPS1\n$(date)\n\\[\[\e[0;32m\]\u@\h \[\e[0;33m\]\w " " \[\e[1;34m\]\n\n $(__HOPPER_RANDOM_EMOJI) \\$\[\e[0m\] ";'
fi
