#!/bin/bash

# ================================================================
#  Right Click File Uninstall
#  Removes "Create a file here..." from the right-click context menu
#  Restores the original DING desktopManager.js from backup
#  Author : sypher93
#  License : GNUv3
# ================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

LOG_DIR="/var/log/right_click_file"
LOG_FILE="$LOG_DIR/install.log"
MANIFEST="$LOG_DIR/installed_files.txt"
DING_FILE="/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/desktopManager.js"

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$LOG_DIR"
    echo "[$ts] [$level] $msg" >> "$LOG_FILE"
    case "$level" in
        INFO)  info    "$msg" ;;
        OK)    success "$msg" ;;
        WARN)  warning "$msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg"; exit 1 ;;
    esac
}

echo ""
echo "================================================================"
echo "            Right Click File    --    Uninstallation            "
echo "================================================================"
echo ""

mkdir -p "$LOG_DIR"
{
    echo ""
    echo "================================================================"
    echo "  Uninstallation started : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================"
} >> "$LOG_FILE"

read -p "  This will remove all components of right_click_file. Continue? (y/n): " CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && echo "" && log INFO "Uninstallation cancelled by user." && echo "" && exit 0
echo ""

log INFO "Reading installation manifest..."
if [ -f "$MANIFEST" ]; then
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        declare "$key=$value"
    done < "$MANIFEST"
    log OK "Manifest loaded: $MANIFEST"
else
    log WARN "Manifest not found, using default paths."
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(eval echo "~$REAL_USER")
    MAIN_SCRIPT="$REAL_HOME/.local/bin/create-file-here.sh"
    NAUTILUS_EXT="$REAL_HOME/.local/share/nautilus-python/extensions/create_file_here.py"
fi

log INFO "Removing Nautilus extension..."
if [ -f "$NAUTILUS_EXT" ]; then
    rm -f "$NAUTILUS_EXT"
    log OK "Removed: $NAUTILUS_EXT"
else
    log WARN "Nautilus extension not found, skipping: $NAUTILUS_EXT"
fi

log INFO "Removing main script..."
if [ -f "$MAIN_SCRIPT" ]; then
    rm -f "$MAIN_SCRIPT"
    log OK "Removed: $MAIN_SCRIPT"
else
    log WARN "Main script not found, skipping: $MAIN_SCRIPT"
fi

log INFO "Restoring DING desktop manager..."

if [ ! -f "$DING_FILE" ]; then
    log WARN "desktopManager.js not found, skipping DING restore."
else
    BACKUP_PATH=""

    if [ -f "$LOG_DIR/last_backup.txt" ]; then
        CANDIDATE=$(cat "$LOG_DIR/last_backup.txt")
        [ -f "$CANDIDATE" ] && BACKUP_PATH="$CANDIDATE"
    fi

    if [ -z "$BACKUP_PATH" ]; then
        BACKUP_PATH=$(ls -t "${DING_FILE}".backup.* 2>/dev/null | head -1)
    fi

    if [ -n "$BACKUP_PATH" ]; then
        log INFO "Restoring from backup: $BACKUP_PATH"
        cp "$BACKUP_PATH" "$DING_FILE"
        log OK "desktopManager.js restored"

        rm -f "${DING_FILE}".backup.*
        rm -f "$LOG_DIR/last_backup.txt"
        log OK "Backup files removed"
    else
        log WARN "No backup found -- removing patch markers manually..."
        python3 << PYEOF
import re, sys

with open('$DING_FILE') as f:
    c = f.read()

if 'PATCH_CREATE_FILE_HERE' not in c:
    print("  No patch detected in desktopManager.js, nothing to remove.")
    sys.exit(0)

cleaned = re.sub(
    r'\s*// PATCH_CREATE_FILE_HERE.*?// END_PATCH\n',
    '\n',
    c,
    flags=re.DOTALL
)

with open('$DING_FILE', 'w') as f:
    f.write(cleaned)
print("  Patch markers removed successfully.")
PYEOF
        log OK "DING patch removed manually"
    fi
fi

log INFO "Cleaning up manifest..."
rm -f "$MANIFEST"
log OK "Manifest removed"

log INFO "Restarting Nautilus..."
sudo -u "$REAL_USER" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $REAL_USER)/bus" \
    nautilus -q 2>/dev/null || true
sleep 1
sudo -u "$REAL_USER" \
    DISPLAY=:0 \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $REAL_USER)/bus" \
    nohup nautilus > /dev/null 2>&1 &
log OK "Nautilus restarted"

{
    echo "================================================================"
    echo "  Uninstallation completed : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Log preserved at         : $LOG_FILE"
    echo "================================================================"
} >> "$LOG_FILE"

echo ""
echo "================================================================"
echo "                    Uninstallation complete                     "
echo "================================================================"
echo ""
echo "  Nautilus extension  -- Removed  [active now]"
echo "  Main script         -- Removed  [active now]"
echo "  DING patch          -- Restored [needs reboot]"
echo ""
echo "  Log preserved at: $LOG_FILE"
echo ""
echo "----------------------------------------------------------------"
warning "A reboot is required to fully remove the desktop right-click entry."
echo "----------------------------------------------------------------"
echo ""
read -p "  Reboot now? (y/n): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo ""
    log INFO "Rebooting in 3 seconds... Press Ctrl+C to cancel."
    echo "  Reboot initiated by user." >> "$LOG_FILE"
    sleep 3
    reboot
else
    echo ""
    log WARN "Reboot skipped. Run 'sudo reboot' when ready."
    echo ""
fi