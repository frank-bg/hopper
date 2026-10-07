# shellcheck shell=bash
# Show git status of watched repos at login, but only the ones that need
# attention: dirty, ahead or behind their upstream. Cross-shell (bash + zsh).
# Requires: $__hopper_dir, compat.sh (_mtime/_sha256), emoji.sh.
#
# Which repos get checked (__hopper_check_repos, called by the entrypoint):
#   - always: hopper itself and ~/projects/*
#   - per-host extras: one path per line in .repo_status_sources (# comments,
#     leading ~ expanded). Gitignored, so each machine curates its own list.
#   - drop-ins: call `__HOPPER_REPO_STATUS <dir>` for their own repos.
#
# During login every repo is only queued; __hopper_check_repos then fetches
# the whole queue in parallel and prints the statuses in queue order.

mkdir -p "${__hopper_dir}/cache"

__hopper_repo_queue=()
__hopper_repo_queueing=1

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

# Public API for drop-ins: queue a repo during login, check it right away
# afterwards (a call by hand still works).
__HOPPER_REPO_STATUS() {
    local dir=${1%/} queued
    if [[ -z $__hopper_repo_queueing ]]; then
        __hopper_flush_repo_status "$dir"
        return 0
    fi
    for queued in "${__hopper_repo_queue[@]}"; do
        [[ $queued == "$dir" ]] && return 0
    done
    __hopper_repo_queue+=("$dir")
}

__hopper_status_cache() {
    local hash
    hash=$(printf '%s' "$1" | _sha256 | cut -d ' ' -f 1)
    printf '%s' "${__hopper_dir}/cache/.repo_status_${hash}"
}

# True when $1 is a git repo / worktree whose status was not shown in the
# last hour.
__hopper_status_due() {
    if [[ ! -d $1/.git && ! -f $1/.git ]]; then
        return 1
    fi

    local cache_file
    cache_file=$(__hopper_status_cache "$1")
    [[ -f $cache_file ]] || return 0

    local current_timestamp seconds_ago previous_timestamp file_ts
    current_timestamp=$(date +%s)
    seconds_ago=$((60 * 60))
    previous_timestamp=$((current_timestamp - seconds_ago))
    file_ts=$(_mtime "$cache_file")

    [[ $file_ts -lt $previous_timestamp ]]
}

# Fetch every repo given at once. Everything runs inside a subshell so the
# interactive shell prints no job-control noise ([1] 12345 / Done). A progress
# line counts the finished fetches and is wiped at the end; failures are
# reported after it. No prompts: a dozen passphrase prompts at once would be
# unusable, so a fetch without a key in the agent fails and the status falls
# back to the last fetch.
__hopper_fetch_repos() {
    (
        progress="${__hopper_dir}/cache/.fetch_progress.$$"
        errors="${__hopper_dir}/cache/.fetch_errors.$$"
        : >"$progress"
        : >"$errors"
        total=$#
        # a literal ~ in the replacement would be expanded back to $HOME by bash
        tilde='~'
        export GIT_TERMINAL_PROMPT=0

        for dir in "$@"; do
            (
                # keep a repo's own core.sshCommand, only add the batch options
                ssh_cmd=$(git -C "$dir" config core.sshCommand) || ssh_cmd=ssh
                if ! err=$(GIT_SSH_COMMAND="$ssh_cmd -o BatchMode=yes -o ConnectTimeout=10" \
                    git -C "$dir" fetch --quiet 2>&1); then
                    printf '⚠️  fetch failed: %s — %s\n' \
                        "${dir/#$HOME/$tilde}" "${err%%$'\n'*}" >>"$errors"
                fi
                # one byte per finished fetch: O_APPEND keeps concurrent writes whole
                printf . >>"$progress"
            ) &
        done

        if [[ -t 1 ]]; then
            while :; do
                finished=$(($(wc -c <"$progress")))
                printf '\r\033[K⇣ fetch %d/%d…' "$finished" "$total"
                [[ $finished -ge $total ]] && break
                sleep 0.1
            done
        fi
        wait
        [[ -t 1 ]] && printf '\r\033[K'
        cat "$errors"
        rm -f "$progress" "$errors"
    )
}

__hopper_print_repo_status() {
    # Call directly and read $__HOPPER_EMOJI rather than capturing twice
    # with $(...): in zsh each subshell re-seeds $RANDOM identically, which
    # would make both emoji runs match. See lib/emoji.sh. With hopper.emoji
    # off the emoji is empty and the banner keeps a plain frame.
    (
        cd "$1" || exit
        # a second porcelain line means a dirty tree; the ## header carries
        # [ahead N, behind M]. Without an upstream only a dirty tree counts.
        st=$(git status --porcelain -b 2>/dev/null) || exit
        case "$st" in
            *$'\n'* | *'[ahead '* | *'[behind '*) ;;
            *) exit 0 ;;
        esac
        __HOPPER_RANDOM_EMOJI 5 >/dev/null; left="${__HOPPER_EMOJI:-═════}"
        __HOPPER_RANDOM_EMOJI 5 >/dev/null; right="${__HOPPER_EMOJI:-═════}"
        echo "" && echo "$left $PWD $right" && git status -s -b
    )
    touch "$(__hopper_status_cache "$1")"
}

__hopper_flush_repo_status() {
    local dir due=() fetch=()
    for dir in "$@"; do
        __hopper_status_due "$dir" || continue
        due+=("$dir")
        if [[ -d $dir/.git ]] && __HOPPER_DO_FETCH "$dir"; then
            fetch+=("$dir")
        fi
    done

    [[ ${#fetch[@]} -gt 0 ]] && __hopper_fetch_repos "${fetch[@]}"

    for dir in "${due[@]}"; do
        __hopper_print_repo_status "$dir"
    done
}

__hopper_check_repos() {
    # zsh errors on a glob with no matches; keep that local to this function.
    [ -n "$ZSH_VERSION" ] && setopt local_options no_nomatch

    __hopper_repo_queueing=1
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

    # drop-ins queued theirs while conf-d loaded them, so theirs show first
    unset __hopper_repo_queueing
    __hopper_flush_repo_status "${__hopper_repo_queue[@]}"
    __hopper_repo_queue=()
}
