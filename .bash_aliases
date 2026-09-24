# hopper bash entrypoint.
# debian based:  ln -s ~/hopper/.bash_aliases ~/
# anything else: source ~/hopper/.bash_aliases from ~/.bashrc
#
# Other repos extend the shell through drop-ins in ~/.config/hopper/conf.d/
# (see lib/conf-d.sh and bin/hopper-link); hopper itself knows none of them.

# start timing script load
__hopper_load_start=$(date +%s%N)

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
    MYPS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]"
    PS1="$MYPS1$PS1"
    ;;
*)
    MYPS1=''
    ;;
esac

__hopper_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# platform shims (_mtime, _sha256) for the rest of lib/
source "${__hopper_dir}/lib/compat.sh"

# environment: exports + PATH
source "${__hopper_dir}/lib/env.sh"

# feature toggles, prompted once per host (also used by drop-ins)
source "${__hopper_dir}/lib/flag.sh"

# git config (aliases + settings)
source "${__hopper_dir}/lib/git-config.sh"

# composer config
if command -v composer > /dev/null 2>&1; then
    __hopper_ask_flag hopper.composerGlobalBinToPath "add composer global bin to path?"
    __hopper_ask_flag hopper.composerIncludeCompletionScript "composer: include completion script?"

    # add composer global bin to path
    if [[ "$(git config --bool hopper.composerGlobalBinToPath)" == 'true' ]]; then
        __hopper_composer_bin_dir="$(composer config -g home 2>/dev/null)/vendor/bin"
        if [[ -d $__hopper_composer_bin_dir ]]; then
            PATH="$__hopper_composer_bin_dir:$PATH"
        fi
        unset __hopper_composer_bin_dir
    fi

    # composer: include completion script
    if [[ "$(git config --bool hopper.composerIncludeCompletionScript)" == 'true' ]]; then
        if [[ ! -f "${__hopper_dir}/cache/composer_completion.sh" ]]; then
            mkdir -p "${__hopper_dir}/cache"
            composer completion > "${__hopper_dir}/cache/composer_completion.sh"
        fi
        source "${__hopper_dir}/cache/composer_completion.sh"
    fi
fi

# prompt + random emoji. emoji.sh must load before repo-status, which uses the
# emoji too.
source "$__hopper_dir/lib/emoji.sh"
source "$__hopper_dir/lib/prompt.sh"

# always-available helpers (ahi-fue, bye, wttr, ..)
source "${__hopper_dir}/lib/helpers.sh"

# git status of watched repos: defines __HOPPER_REPO_STATUS, so drop-ins can
# add their own repos
source "${__hopper_dir}/lib/repo-status.sh"

# drop-ins from other repos (~/.config/hopper/conf.d/*.sh)
source "${__hopper_dir}/lib/conf-d.sh"

# hopper's own watched repos, after the drop-ins' so theirs show first
__hopper_check_repos

# symlink ~/.config/kitty to the repo (kitten rewrites files, so hardlinks
# break — a dir symlink survives)
if [[ -n $DISPLAY ]]; then
    __kitty_repo_dir="${__hopper_dir}/config/kitty"
    if [[ ! -L $HOME/.config/kitty ]]; then
        if [[ -d $HOME/.config/kitty ]]; then
            echo "Removing existing ~/.config/kitty and symlinking to $__kitty_repo_dir"
            rm -rf "$HOME/.config/kitty"
        fi
        mkdir -p "$HOME/.config"
        ln -s "$__kitty_repo_dir" "$HOME/.config/kitty"
    fi
    # kitty.conf includes this file; it must exist even when this host needs
    # no settings of its own
    [[ -f $__kitty_repo_dir/local.conf ]] || touch "$__kitty_repo_dir/local.conf"
    unset __kitty_repo_dir
fi

# zellij config dir + `ez`
source "${__hopper_dir}/lib/zellij.sh"

# display script load time if >= 100ms or HOPPER_TIMING=1
__hopper_load_end=$(date +%s%N)
__hopper_load_elapsed=$(( (__hopper_load_end - __hopper_load_start) / 1000000 ))
if [[ -n "$HOPPER_TIMING" ]] || (( __hopper_load_elapsed >= 100 )); then
    printf "⏱️  .bash_aliases: %d ms\n" "$__hopper_load_elapsed"
fi
unset __hopper_load_start __hopper_load_end __hopper_load_elapsed
