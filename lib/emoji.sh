# shellcheck shell=bash
# __HOPPER_RANDOM_EMOJI [count] — print `count` random emojis (default 1),
# and also store the result in the global $__HOPPER_EMOJI.
# Cross-shell: works in bash and zsh. Used by the prompt and by
# __HOPPER_REPO_STATUS. Falls back to "═" on dumb terminals.
#
# The set comes from `git config hopper.emoji`, read once when this file is
# sourced (a change applies to the next shell):
#   unset / animals      the default
#   fruits, hearts, monkeys, moons, vehicles, clocks, sports, books, globes,
#   faces                another named set
#   off / false / no / none
#                        no emoji: __HOPPER_EMOJI comes back empty
#   anything else        a literal space-separated list, e.g. "🦀 🐙 🦑"
#
# Read $__HOPPER_EMOJI instead of capturing with $(...) when the caller is
# zsh: zsh re-seeds $RANDOM to the *same* value in every forked subshell, so
# $(__HOPPER_RANDOM_EMOJI) returns an identical emoji on each call within a
# shell. Calling the function directly runs it in the current shell, where
# $RANDOM advances normally. (bash advances $RANDOM across subshells, so its
# $(...) callers are unaffected.)

__hopper_emoji_load() {
    local choice
    choice=$(git config --get hopper.emoji 2>/dev/null)

    case "$choice" in
    off | false | no | none)
        __HOPPER_EMOJIS=()
        return 0
        ;;
    esac

    case "$TERM" in
    xterm* | rxvt*) ;;
    *)
        __HOPPER_EMOJIS=("═")
        return 0
        ;;
    esac

    case "${choice:-animals}" in
    animals) __HOPPER_EMOJIS=("🐶" "🐱" "🐭" "🐹" "🐰" "🦊" "🐻" "🐼" "🐻‍❄️" "🐨" "🐯" "🦁" "🐮" "🐷" "🐸" "🐵" "🐔" "🐺" "🐗" "🐴" "🦄" "🫎" "🦝" "🐲") ;;
    fruits) __HOPPER_EMOJIS=("🍏" "🍎" "🍐" "🍊" "🍋" "🍌" "🍉" "🍇" "🍓" "🫐" "🍈" "🍒" "🍑" "🥭" "🍍" "🥥" "🥝" "🍅" "🍆" "🥑" "🥦" "🫛" "🥬" "🥒" "🫑" "🌽" "🥕" "🫒" "🧄" "🧅" "🥔" "🍠" "🫘") ;;
    hearts) __HOPPER_EMOJIS=("❤️" "🧡" "💛" "💚" "💙" "💜" "🖤" "🤍" "🤎" "🔴" "🟠" "🟡" "🟢" "🔵" "🟣" "⚫️" "⚪️" "🟤" "🟥" "🟧" "🟨" "🟩" "🟦" "🟪" "⬛️" "⬜️" "🟫") ;;
    monkeys) __HOPPER_EMOJIS=("🐵" "🙈" "🙉" "🙊") ;;
    moons) __HOPPER_EMOJIS=("🌕" "🌖" "🌗" "🌘" "🌑" "🌒" "🌓" "🌔") ;;
    vehicles) __HOPPER_EMOJIS=("🚗" "🚕" "🚙" "🚌" "🚎" "🚓" "🚑" "🚒" "🚐" "🛻" "🚚" "🚛" "🚜" "🛴" "🚲" "🛵" "🛺" "🚡" "🚠" "🚟" "🚃" "🚋" "🚝" "🚄" "🚅" "🚈" "🚂" "🚁") ;;
    clocks) __HOPPER_EMOJIS=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛" "🕜" "🕝" "🕞" "🕟" "🕠" "🕡" "🕢" "🕣" "🕤" "🕥" "🕦" "🕧") ;;
    sports) __HOPPER_EMOJIS=("⚽" "⚾" "🥎" "🏀" "🏐" "🏈" "🏉" "🎾" "🎱") ;;
    books) __HOPPER_EMOJIS=("📕" "📗" "📘" "📙") ;;
    globes) __HOPPER_EMOJIS=("🌎" "🌍" "🌏") ;;
    faces) __HOPPER_EMOJIS=("😀" "😃" "😄" "😁" "😆" "😅" "🤣" "😂" "🙂" "🙃" "😉" "😊" "😇" "🥰" "😍" "🤩" "😘" "😗" "☺️" "😚" "😙" "😋" "😛" "😜" "🤪" "😝" "🤑" "🤗" "🤭" "🤫" "🤔") ;;
    *)
        # A literal list. zsh does not word-split unquoted parameters; ${=...}
        # does, and eval keeps that syntax away from bash's parser.
        if [ -n "$ZSH_VERSION" ]; then
            eval '__HOPPER_EMOJIS=(${=choice})'
        else
            read -r -a __HOPPER_EMOJIS <<< "$choice"
        fi
        ;;
    esac
}

__HOPPER_RANDOM_EMOJI() {
    local out="" i idx n=${#__HOPPER_EMOJIS[@]}
    if (( n == 0 )); then
        __HOPPER_EMOJI=""
        return 0
    fi

    # zsh indexes arrays from 1, bash from 0.
    local base=0
    [ -n "$ZSH_VERSION" ] && base=1

    for (( i = 0; i < ${1:-1}; i++ )); do
        idx=$(( RANDOM % n + base ))
        out="${out}${__HOPPER_EMOJIS[$idx]}"
    done
    __HOPPER_EMOJI="$out"
    printf '%s\n' "$out"
}

__hopper_emoji_load
