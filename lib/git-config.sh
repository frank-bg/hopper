# shellcheck shell=bash
# Global git config — aliases and settings. Cross-shell (bash + zsh).
# Each setting only applies if not already set (so it never clobbers user config).
# Requires $__hopper_dir (set by the entrypoint before sourcing this).

if [[ -z $(git config --global alias.lg 2>/dev/null) ]]; then
    git config --global alias.lg 'log --oneline --decorate --all --graph'
fi

if [[ -z $(git config --global alias.s 2>/dev/null) ]]; then
    git config --global alias.s 'status -s -b'
fi

if [[ -z $(git config --global alias.pfl 2>/dev/null) ]]; then
    git config --global alias.pfl 'push --force-with-lease'
fi

# Also repoint it when the file it names is gone (the repo that used to carry
# it was moved or deleted); a path to an existing file is left alone.
__hopper_excludes=$(git config --global core.excludesFile 2>/dev/null)
if [[ -z $__hopper_excludes || ! -f ${__hopper_excludes/#\~/$HOME} ]]; then
    git config --global core.excludesFile "${__hopper_dir}/global.gitignore"
fi
unset __hopper_excludes
