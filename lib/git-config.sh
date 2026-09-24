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

# Opt-in: git identity lives in each repo, never globally, so a repo without its own
# user.name/user.email refuses to commit instead of borrowing whichever identity is
# global. useConfigOnly stops git from guessing one from $USER@hostname (on macOS the
# guess succeeds). It runs on every shell start, so it heals itself: a global identity
# set by mistake (a tool, a copy-pasted `git config --global user.email`, an old
# setup) is stripped again at the next shell, and useConfigOnly restored if unset.
# It speaks whenever it removes something, because that changes what the next
# commit does. The only place hopper removes user config, and only after a yes.
__hopper_ask_flag hopper.perRepoIdentity "git: require a per-repo identity (remove the global one)?"
if [[ "$(git config --bool hopper.perRepoIdentity)" == 'true' ]]; then
    [[ $(git config --global --bool user.useConfigOnly 2>/dev/null) == 'true' ]] ||
        git config --global user.useConfigOnly true
    for __hopper_k in user.name user.email author.name author.email committer.name committer.email; do
        if __hopper_v=$(git config --global --get "$__hopper_k" 2>/dev/null); then
            git config --global --unset-all "$__hopper_k"
            echo "hopper: removed global git $__hopper_k ($__hopper_v): identity is per repo"
        fi
    done
    unset __hopper_k __hopper_v
fi
