# shellcheck shell=bash
# Show git status of watched repos at login. Cross-shell (bash + zsh).
# Requires: $__hopper_dir, compat.sh (_mtime/_sha256), emoji.sh.
#
# Which repos get checked (__hopper_check_repos, called by the entrypoint):
#   - always: hopper itself and ~/projects/*
#   - per-host extras: one path per line in .repo_status_sources (# comments,
#     leading ~ expanded). Gitignored, so each machine curates its own list.
#   - drop-ins: call `__HOPPER_REPO_STATUS <dir>` for their own repos.

mkdir -p "${__hopper_dir}/cache"

# Throttle `git fetch` to once per 12h per repo (keyed by a hash of the path).
__HOPPER_DO_FETCH() {
    local hash
    hash=$(printf '%s' "$1" | _sha256 | cut -d ' ' -f 1)
    local file="${__hopper_dir}/cache/.do_fetch_${hash}"

    if [[ ! -f $file ]]; then
        touch "$file"
        return 0
    fi

    local current_timestamp seconds_ago previous_timestamp file_ts
    current_timestamp=$(date +%s)
    seconds_ago=$((12 * 60 * 60))
    previous_timestamp=$((current_timestamp - seconds_ago))
    file_ts=$(_mtime "$file")

    if [[ $file_ts -lt $previous_timestamp ]]; then
        touch "$file"
        return 0
    fi

    return 1
}

__HOPPER_REPO_STATUS() {
    # skip if not a git repo / worktree
    if [[ ! -d $1/.git && ! -f $1/.git ]]; then
        return 0
    fi

    # throttle the whole status check to once per hour per repo
    local hash cache_file
    hash=$(printf '%s' "$1" | _sha256 | cut -d ' ' -f 1)
    cache_file="${__hopper_dir}/cache/.repo_status_${hash}"

    if [[ -f $cache_file ]]; then
        local current_timestamp seconds_ago previous_timestamp file_ts
        current_timestamp=$(date +%s)
        seconds_ago=$((60 * 60))
        previous_timestamp=$((current_timestamp - seconds_ago))
        file_ts=$(_mtime "$cache_file")

        if [[ $file_ts -ge $previous_timestamp ]]; then
            return 0  # cache still valid, skip
        fi
    fi

    if [[ -d $1 ]]; then
        if [[ -d $1/.git ]] && __HOPPER_DO_FETCH "$1"; then
            ( cd "$1" && git fetch --quiet )
        fi
        # Call directly and read $__HOPPER_EMOJI rather than capturing twice
        # with $(...): in zsh each subshell re-seeds $RANDOM identically, which
        # would make both emoji runs match. See lib/emoji.sh. With hopper.emoji
        # off the emoji is empty and the banner keeps a plain frame.
        (
            cd "$1" || exit
            __HOPPER_RANDOM_EMOJI 5 >/dev/null; left="${__HOPPER_EMOJI:-═════}"
            __HOPPER_RANDOM_EMOJI 5 >/dev/null; right="${__HOPPER_EMOJI:-═════}"
            echo "" && echo "$left $PWD $right" && git status -s -b
        )
        touch "$cache_file"
    fi
}

__hopper_check_repos() {
    # zsh errors on a glob with no matches; keep that local to this function.
    [ -n "$ZSH_VERSION" ] && setopt local_options no_nomatch

    __HOPPER_REPO_STATUS "$__hopper_dir"

    # per-host list
    local src="${__hopper_dir}/.repo_status_sources"
    if [[ -f $src ]]; then
        local line
        while read -r line; do
            case "$line" in '' | '#'*) continue ;; esac
            __HOPPER_REPO_STATUS "${line/#\~/$HOME}"
        done < "$src"
    fi

    if [[ -d $HOME/projects ]]; then
        local dir
        for dir in "$HOME"/projects/*/; do
            [[ -e $dir ]] && __HOPPER_REPO_STATUS "$dir"
        done
    fi
}
