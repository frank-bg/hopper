# shellcheck shell=bash
# zellij: config dir in the repo, and `ez` to attach to the `main` session.

export ZELLIJ_CONFIG_DIR="$__hopper_dir/config/zellij"

# if zellij installed, remind to maybe use it
if [[ -z "$ZELLIJ" ]] && command -v zellij &>/dev/null; then
    echo ""
    echo "💡💡💡 Tip: you have zellij installed, maybe you want to use it (ez) 💡💡💡"
    echo ""
    ez() {
        # declared once, outside the loop: zsh prints an existing local when it
        # is declared again
        local pid cmdline
        # kick out other zellij clients so this terminal becomes the only attachment
        for pid in $(pgrep -x zellij 2>/dev/null); do
            [[ $pid -eq $$ ]] && continue
            # ps, not /proc: macOS has no /proc, and an empty cmdline would
            # kill the server with every session
            cmdline=$(ps -o args= -p "$pid" 2>/dev/null)
            [[ -z "$cmdline" || "$cmdline" == *"--server"* ]] && continue
            kill "$pid" 2>/dev/null
        done
        exec zellij attach -c main
    }
fi
