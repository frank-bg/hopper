# shellcheck shell=bash
# Always-available helpers. Cross-shell (bash + zsh).
# Requires $__hopper_dir (set by the entrypoint before sourcing this).

# Pull the hopper repo (and its posh-git-sh submodule).
hpull() { ( cd "$__hopper_dir" && git pull && git submodule update --init ); }

# Append `; ahi-fue` to a long command to get an ntfy.sh ping when it finishes,
# tagged with success/failure. e.g.  make build; ahi-fue
# The topic is public (this also runs on client servers with no tailnet), so
# secrets in the command are redacted before sending and the message is not
# cached server-side (`Cache: no`) — a subscriber that is offline at that
# moment will not get it on reconnect; that is the price.
ahi-fue() {
    local exit_code=$?
    local tag
    tag=$( [ "$exit_code" = 0 ] && echo tada || echo facepalm )
    # Strip the leading history index and a trailing "; ahi-fue".
    # -E + [[:space:]] keeps this portable across GNU sed and macOS/BSD sed.
    local cmd
    cmd=$( history | tail -n1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]*//; s/[;&|][[:space:]]*ahi-fue[[:space:]]*$//' )

    # Redact what looks like a secret: `key=value` for password/passwd/token/
    # secret/api_key (as a suffix, so DB_PASSWORD= and ?token= count; quoted or
    # bare value), `Authorization: Bearer|Basic ...`, and the password in
    # scheme://user:pass@host. Plain POSIX ERE only: no \s, \b or the I flag,
    # which macOS/BSD sed lacks — case-insensitivity is spelled out per letter.
    local kv='([Pp][Aa][Ss][Ss][Ww]([Oo][Rr][Dd]|[Dd])|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy])'
    local auth='[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn]:[[:space:]]*([Bb][Ee][Aa][Rr][Ee][Rr]|[Bb][Aa][Ss][Ii][Cc])[[:space:]]+'
    cmd=$( printf '%s' "$cmd" | sed -E \
        -e "s#(://[^/:@[:space:]]+):[^/@[:space:]]+@#\1:***@#g" \
        -e "s/(${kv}=)(\"[^\"]*\"|'[^']*'|[^\"'[:space:];&|]*)/\1***/g" \
        -e "s/(${auth})[^\"'[:space:]]+/\1***/g" )

    local topic
    topic=$(git config --get hopper.ahiFueTopic)
    if [[ -z "$topic" ]]; then
        echo -n "Enter topic for ntfy message: "
        read topic
        git config --global hopper.ahiFueTopic "$topic"
    fi

    curl -s \
        -H "Tags: $tag" \
        -H "Title: $(hostname -s)" \
        -H "Cache: no" \
        -d "$cmd" \
        https://ntfy.sh/"$topic" &>/dev/null
}

alias bye='exit'
alias wttr='curl https://wttr.in'
alias ..='cd ..'
