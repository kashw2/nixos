#!/bin/sh
# Emits a MODE: marker line, then the preview body for that mode.
p=$1
style=$2

if [ -d "$p" ]; then
    echo "MODE:text"
    ls -A -1 --group-directories-first --indicator-style=slash "$p" 2>/dev/null | head -n 200
    exit 0
fi

[ -f "$p" ] || exit 0
[ -s "$p" ] || { echo "MODE:text"; exit 0; }

name=$(printf '%s' "${p##*/}" | tr 'A-Z' 'a-z')
case "$name" in
    *.png | *.jpg | *.jpeg | *.gif | *.webp | *.bmp | *.ico | *.svg)
        echo "MODE:image"
        exit 0
        ;;
esac

LC_ALL=C grep -qI . "$p" 2>/dev/null || { echo "MODE:binary"; exit 0; }

snippet=$(head -c 65536 "$p" | head -n 200)

# chroma right-aligns the numbers already; the awk only reserves the two cells
# signcolumn=yes leaves to their left. It stops at the code cell so a number
# literal ending a line of code is never touched.
highlighted=$(
    printf '%s\n' "$snippet" \
        | chroma --fail --html --html-only --html-inline-styles \
            --html-lines --html-lines-table --html-tab-width=2 \
            --style="$style" --filename "${p##*/}" 2>/dev/null \
        | sed -e 's|display:flex; *||g' -e 's|display:grid;||g' \
        | awk '
            /width:100%/ { incode = 1 }
            !incode && match($0, /> *[0-9]+$/) {
                printf "%s>  %s\n", substr($0, 1, RSTART - 1), \
                    substr($0, RSTART + 1, RLENGTH - 1)
                next
            }
            { print }
        '
)

if [ -n "$highlighted" ]; then
    echo "MODE:html"
    printf '%s\n' "$highlighted"
else
    echo "MODE:text"
    printf '%s\n' "$snippet"
fi
