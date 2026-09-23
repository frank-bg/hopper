# shellcheck shell=bash
# Environment: exports + PATH. Cross-shell (bash + zsh).
# Requires $__hopper_dir (set by the entrypoint before sourcing this).

export GH_EDITOR="code --wait"
export LESSCHARSET=utf-8 # fix less showing weird chars with utf-8 files

# sudo -A from no-TTY contexts (e.g. an AI agent's shell tool): GUI askpass helper
[[ -x "$__hopper_dir/bin/sudo-askpass" ]] && export SUDO_ASKPASS="$__hopper_dir/bin/sudo-askpass"

# Prepend dirs to PATH if they exist and aren't already there.
# Last one wins: each is prepended, so the last dir listed ends up first in PATH.
# The /Applications ones are macOS: VS Code's `code`, Sublime Merge's `smerge` and
# Sublime Text's `subl` CLIs, which the apps don't put on the PATH by themselves
# (terminal use only — GUI apps never see this PATH).
for __d in "$HOME/.local/bin" "$__hopper_dir/bin" \
           "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" \
           "/Applications/Sublime Merge.app/Contents/SharedSupport/bin" \
           "/Applications/Sublime Text.app/Contents/SharedSupport/bin"; do
    [[ -d "$__d" && ":$PATH:" != *":$__d:"* ]] && PATH="$__d:$PATH"
done
unset __d
export PATH
