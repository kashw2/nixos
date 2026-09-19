#!/bin/sh
# Emits one typed record per line for the launcher to group:
#   F|size|mtime|path            a file
#   D|size|mtime|path            a directory
#   S|name|windows|attached|path|activity   a tmux session
#   W|session|index|name|active             a window in that session
q=$1
[ -n "$q" ] || exit 0

if command -v fd >/dev/null 2>&1; then
    fd --type f --max-results 25 \
        --exclude .git --exclude node_modules --exclude .cache \
        -- "$q" "$HOME" 2>/dev/null \
        | while IFS= read -r f; do stat -c "F|%s|%Y|%n" "$f" 2>/dev/null; done
    fd --type d --max-results 15 \
        --exclude .git --exclude node_modules --exclude .cache \
        -- "$q" "$HOME" 2>/dev/null \
        | while IFS= read -r d; do stat -c "D|%s|%Y|%n" "${d%/}" 2>/dev/null; done
fi

if command -v tmux >/dev/null 2>&1; then
    tmux list-sessions -F \
        "S|#{session_name}|#{session_windows}|#{session_attached}|#{session_path}|#{session_activity}" \
        2>/dev/null
    tmux list-windows -a -F \
        "W|#{session_name}|#{window_index}|#{window_name}|#{window_active}" \
        2>/dev/null
fi
