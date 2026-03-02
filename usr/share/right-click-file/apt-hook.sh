#!/bin/bash
# /usr/share/right-click-file/apt-hook.sh
# right-click-file | Copyright (C) 2026 sypher93 <sypher93@proton.me> | GPLv3


DING_FILE="/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/desktopManager.js"
STATE_DIR="/var/lib/right-click-file"
HASH_FILE="$STATE_DIR/ding.sha256"
LOG_DIR="/var/log/right_click_file"
LOG_FILE="$LOG_DIR/install.log"
PATCH_SCRIPT="/usr/share/right-click-file/patch-ding.py"

log() {
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> "$LOG_FILE"
}

notify_users() {
    local msg="$1"
    local urgency="${2:-normal}"

    while IFS= read -r line; do
        local user display dbus
        user=$(echo "$line" | awk '{print $1}')
        display=$(echo "$line" | awk '{print $2}')
        dbus=$(echo "$line" | awk '{print $3}')
        [ -z "$user" ] || [ -z "$dbus" ] && continue
        sudo -u "$user" \
            DISPLAY="$display" \
            DBUS_SESSION_BUS_ADDRESS="$dbus" \
            notify-send \
                --app-name="right-click-file" \
                --icon="dialog-information" \
                --urgency="$urgency" \
                "right-click-file" \
                "$msg" 2>/dev/null || true
    done < <(
        who | awk '{print $1, $5}' | tr -d '()' | sort -u | while read -r u d; do
            [ -z "$d" ] && continue
            pid=$(pgrep -u "$u" gnome-session 2>/dev/null | head -1)
            [ -z "$pid" ] && continue
            dbus_addr=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$pid"/environ 2>/dev/null \
                | tr -d '\0' | sed 's/DBUS_SESSION_BUS_ADDRESS=//')
            [ -n "$dbus_addr" ] && echo "$u $d $dbus_addr"
        done
    )
}

[ -f "$DING_FILE" ] || exit 0

[ -f "$HASH_FILE" ] || exit 0

CURRENT_HASH=$(sha256sum "$DING_FILE" | awk '{print $1}')
STORED_HASH=$(cat "$HASH_FILE")

[ "$CURRENT_HASH" = "$STORED_HASH" ] && exit 0

log "INFO" "apt-hook: DING updated detected (hash changed)"
log "INFO" "  stored : $STORED_HASH"
log "INFO" "  current: $CURRENT_HASH"

BACKUP_DIR="$STATE_DIR/backups"
mkdir -p "$BACKUP_DIR"
BACKUP="$BACKUP_DIR/desktopManager.js.$(date +%Y%m%d_%H%M%S)"
cp "$DING_FILE" "$BACKUP"
log "INFO" "Backup saved: $BACKUP"

if python3 "$PATCH_SCRIPT" apply >> "$LOG_FILE" 2>&1; then
    log "OK" "apt-hook: patch re-applied successfully after DING update"
    echo "$CURRENT_HASH" > "$HASH_FILE"
    notify_users "DING was updated. The \"Create a file here...\" patch has been re-applied automatically. A reboot is required to activate it on the desktop." "normal"
    log "INFO" "apt-hook: users notified (patch re-applied)"
else
    log "WARN" "apt-hook: patch FAILED after DING update -- manual reinstall may be required"
    notify_users "DING was updated but the \"Create a file here...\" patch could not be re-applied automatically.\n\nRun: sudo apt reinstall right-click-file\n\nSee: $LOG_FILE" "critical"
    log "INFO" "apt-hook: users notified (patch failed)"
    exit 1
fi

exit 0