#!/bin/bash

FOLDER="${1:-}"
[ -z "$FOLDER" ] || [ ! -d "$FOLDER" ] && FOLDER="$HOME/Desktop"
[ ! -d "$FOLDER" ] && FOLDER="$HOME"

NAME=$(zenity --entry \
    --title="New file" \
    --text="Folder: $FOLDER\n\nFile name:" \
    --entry-text="untitled.txt" \
    --no-markup \
    --width=500 2>/dev/null)

[ $? -ne 0 ] || [ -z "$NAME" ] && exit 0

NAME=$(echo "$NAME" | tr -d '/')
TARGET="$FOLDER/$NAME"

if [ -f "$TARGET" ]; then
    zenity --question \
        --title="File already exists" \
        --text="$NAME already exists in this folder.\nOpen it anyway?" \
        --no-markup \
        --width=380 2>/dev/null || exit 0
else
    touch "$TARGET" || {
        zenity --error \
            --title="Error" \
            --text="Could not create the file.\nCheck permissions on:\n$FOLDER" \
            --no-markup \
            --width=400 2>/dev/null
        exit 1
    }
fi

xdg-open "$TARGET" 2>/dev/null &
exit 0
