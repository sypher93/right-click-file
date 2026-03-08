#!/bin/bash
# right-click-file — Copyright (C) 2026 sypher93 <sypher93@proton.me> — GPLv3

FOLDER="${1:-}"
{ [ -z "$FOLDER" ] || [ ! -d "$FOLDER" ]; } && FOLDER="$HOME/Desktop"
[ ! -d "$FOLDER" ] && FOLDER="$HOME"

next_available_name() {
    local folder="$1" name="$2" base ext candidate n

    [ ! -f "$folder/$name" ] && echo "$name" && return

    if [[ "$name" == *.* ]]; then
        base="${name%.*}"
        ext=".${name##*.}"
    else
        base="$name"
        ext=""
    fi

    n=2
    while true; do
        candidate="${base} (${n})${ext}"
        [ ! -f "$folder/$candidate" ] && echo "$candidate" && return
        (( n++ ))
    done
}

SUGGESTED=$(next_available_name "$FOLDER" "untitled.txt")

NAME=$(zenity --entry \
    --title="New file" \
    --text="Folder: $FOLDER\n\nFile name:" \
    --entry-text="$SUGGESTED" \
    --no-markup \
    --width=500 2>/dev/null)

[ $? -ne 0 ] || [ -z "$NAME" ] && exit 0

NAME=$(echo "$NAME" | tr -d '/')

NAME=$(next_available_name "$FOLDER" "$NAME")

TARGET="$FOLDER/$NAME"

touch "$TARGET" || {
    zenity --error \
        --title="Error" \
        --text="Could not create the file.\nCheck permissions on:\n$FOLDER" \
        --no-markup \
        --width=400 2>/dev/null
    exit 1
}

xdg-open "$TARGET" 2>/dev/null &
exit 0