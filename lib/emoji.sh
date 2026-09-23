# shellcheck shell=bash
# __HOPPER_RANDOM_EMOJI [count] — print `count` random emojis (default 1),
# and also store the result in the global $__HOPPER_EMOJI.
# Cross-shell: works in bash and zsh. Used by the prompt and by
# __HOPPER_REPO_STATUS. Falls back to "═" on dumb terminals.
#
# Read $__HOPPER_EMOJI instead of capturing with $(...) when the caller is
# zsh: zsh re-seeds $RANDOM to the *same* value in every forked subshell, so
# $(__HOPPER_RANDOM_EMOJI) returns an identical emoji on each call within a
# shell. Calling the function directly runs it in the current shell, where
# $RANDOM advances normally. (bash advances $RANDOM across subshells, so its
# $(...) callers are unaffected.)

__HOPPER_RANDOM_EMOJI() {
    case "$TERM" in
    xterm* | rxvt*)
        # local EMOJIS=("🍏" "🍎" "🍐" "🍊" "🍋" "🍌" "🍉" "🍇" "🍓" "🫐" "🍈" "🍒" "🍑" "🥭" "🍍" "🥥" "🥝" "🍅" "🍆" "🥑" "🥦" "🫛" "🥬" "🥒" "🫑" "🌽" "🥕" "🫒" "🧄" "🧅" "🥔" "🍠" "🫘")
        local EMOJIS=("🐶" "🐱" "🐭" "🐹" "🐰" "🦊" "🐻" "🐼" "🐻‍❄️" "🐨" "🐯" "🦁" "🐮" "🐷" "🐸" "🐵" "🐔" "🐺" "🐗" "🐴" "🦄" "🫎" "🦝" "🐲")
        # local EMOJIS=("❤️" "🧡" "💛" "💚" "💙" "💜" "🖤" "🤍" "🤎" "🔴" "🟠" "🟡" "🟢" "🔵" "🟣" "⚫️" "⚪️" "🟤" "🟥" "🟧" "🟨" "🟩" "🟦" "🟪" "⬛️" "⬜️" "🟫")
        # local EMOJIS=(🐵 🙈 🙉 🙊)
        # local EMOJIS=(🌕 🌖 🌗 🌘 🌑 🌒 🌓 🌔)
        # local EMOJIS=(🚗 🚕 🚙 🚌 🚎 🚓 🚑 🚒 🚐 🛻 🚚 🚛 🚜 🛴 🚲 🛵 🛺 🚡 🚠 🚟 🚃 🚋 🚝 🚄 🚅 🚈 🚂 🚁)
        # local EMOJIS=(🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛 🕜 🕝 🕞 🕟 🕠 🕡 🕢 🕣 🕤 🕥 🕦 🕧)
        # local EMOJIS=(⚽️ 🏀 🏈 ⚾️ 🥎 🏐)
        # local EMOJIS=(📕 📗 📘 📙)
        # local EMOJIS=(🌎 🌍 🌏)
        # local EMOJIS=(⚽ ⚾ 🥎 🏀 🏐 🏈 🏉 🎾 🎱)
        # local EMOJIS=(😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 😉 😊 😇 🥰 😍 🤩 😘 😗 ☺️ 😚 😙 😋 😛 😜 🤪 😝 🤑 🤗 🤭 🤫 🤔)
        ;;
    *)
        local EMOJIS=("═")
        ;;
    esac

    # zsh indexes arrays from 1, bash from 0.
    local base=0
    [ -n "$ZSH_VERSION" ] && base=1

    local out="" i idx n=${#EMOJIS[@]}
    for (( i = 0; i < ${1:-1}; i++ )); do
        idx=$(( RANDOM % n + base ))
        out="${out}${EMOJIS[$idx]}"
    done
    __HOPPER_EMOJI="$out"
    printf '%s\n' "$out"
}
