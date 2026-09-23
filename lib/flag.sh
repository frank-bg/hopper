# shellcheck shell=bash
# __hopper_ask_flag <git-config-key> <prompt-text>
# Prompts once (y/n), stores the answer as a boolean in global git config, and
# does nothing on subsequent runs. Reused by feature toggles, here and in
# drop-ins. Cross-shell single-char read: bash uses -n, zsh uses -k.
__hopper_ask_flag() {
    local key="$1" prompt="$2" ans
    [[ -n $(git config --global "$key" 2>/dev/null) ]] && return 0
    printf '%s [y/n]: ' "$prompt"
    if [ -n "$ZSH_VERSION" ]; then
        read -k 1 ans
    else
        read -n 1 ans
    fi
    echo ""
    if [[ $ans == 'y' ]]; then
        git config --global "$key" true
    else
        git config --global "$key" false
    fi
}
