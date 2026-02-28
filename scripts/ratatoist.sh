#!/usr/bin/env zsh
# Interactive shell so PATH from .zshrc (pipx/cargo/nvm etc.) is available
zsh -ic ratatoist
ret=$?
if (( ret != 0 )); then
    echo "ratatoist exited with code $ret"
    read "?Press Enter to close"
fi
