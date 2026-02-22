#!/bin/bash

# ================================================================
#  Right Click File
#  Adds "Create a file here..." to the right-click context menu
#  Works on: GNOME desktop (DING) + all Nautilus folders
#  Compatible: Ubuntu 20.04 / 22.04 / 24.04
#  Author : sypher93
#  Licence : GNUv3
# ================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
MAIN_SCRIPT="$REAL_HOME/.local/bin/create-file-here.sh"
DING_FILE="/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/desktopManager.js"
NAUTILUS_EXT_DIR="$REAL_HOME/.local/share/nautilus-python/extensions"
LOG_DIR="/var/log/right_click_file"
LOG_FILE="$LOG_DIR/install.log"

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
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
echo "             Right Click File    --    Installation             "
echo "================================================================"
echo ""

mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
{
    echo ""
    echo "================================================================"
    echo "  Installation started  : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  User                  : $REAL_USER"
    echo "  Home                  : $REAL_HOME"
    echo "================================================================"
} >> "$LOG_FILE"
log INFO "Log file initialized: $LOG_FILE"

log INFO "Validating runtime environment..."
if [ -z "$REAL_USER" ] || [ "$REAL_USER" = "root" ]; then
    log ERROR "Run this script with sudo from a regular user: sudo ./right_click_file.sh"
fi
if [ ! -d "$REAL_HOME" ]; then
    log ERROR "Home directory not found for user '$REAL_USER': $REAL_HOME"
fi
log OK "Environment OK (user: $REAL_USER, home: $REAL_HOME)"

log INFO "Checking dependencies..."
MISSING=()
command -v zenity   &>/dev/null || MISSING+=("zenity")
command -v xdg-open &>/dev/null || MISSING+=("xdg-utils")
python3 -c "
import gi
for v in ['4.0','3.0']:
    try:
        gi.require_version('Nautilus', v)
        from gi.repository import Nautilus
        exit(0)
    except: pass
exit(1)
" 2>/dev/null || MISSING+=("python3-nautilus")

if [ ${#MISSING[@]} -gt 0 ]; then
    log WARN "Installing missing packages: ${MISSING[*]}"
    apt-get install -y "${MISSING[@]}" >> "$LOG_FILE" 2>&1
fi
log OK "Dependencies satisfied"

log INFO "Creating main script..."
mkdir -p "$REAL_HOME/.local/bin"

cat > "$MAIN_SCRIPT" << 'EOF'
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
EOF

chmod +x "$MAIN_SCRIPT"
chown "$REAL_USER:$REAL_USER" "$MAIN_SCRIPT"
log OK "Main script created: $MAIN_SCRIPT"

log INFO "Installing Nautilus extension..."
mkdir -p "$NAUTILUS_EXT_DIR"

cat > "$NAUTILUS_EXT_DIR/create_file_here.py" << PYEOF
import gi, subprocess, os

for _v in ['4.0', '3.0']:
    try:
        gi.require_version('Nautilus', _v)
        break
    except Exception:
        pass

from gi.repository import Nautilus, GObject

SCRIPT = os.path.expanduser("~/.local/bin/create-file-here.sh")

class CreateFileHere(GObject.GObject, Nautilus.MenuProvider):

    def _launch(self, menu, folder):
        subprocess.Popen([SCRIPT, folder])

    def _make_item(self, folder):
        item = Nautilus.MenuItem(
            name="CreateFileHere::new",
            label="Create a file here...",
            tip="Create a new file in this folder",
            icon="document-new",
        )
        item.connect("activate", self._launch, folder)
        return item

    def get_background_items(self, *args):
        folder = args[-1]
        path = folder.get_location().get_path()
        return [self._make_item(path)] if path else []

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) == 1 and files[0].is_directory():
            path = files[0].get_location().get_path()
            return [self._make_item(path)] if path else []
        return []
PYEOF

chown -R "$REAL_USER:$REAL_USER" "$NAUTILUS_EXT_DIR"
log OK "Nautilus extension installed: $NAUTILUS_EXT_DIR/create_file_here.py"

log INFO "Patching DING desktop manager..."

[ ! -f "$DING_FILE" ] && log ERROR "desktopManager.js not found: $DING_FILE"

python3 << PYEOF
import re
with open('$DING_FILE') as f:
    c = f.read()
c = re.sub(
    r'\s*// PATCH_CREATE_FILE_HERE.*?// END_PATCH\n',
    '\n',
    c,
    flags=re.DOTALL
)
with open('$DING_FILE', 'w') as f:
    f.write(c)
print("  Previous patch cleaned.")
PYEOF

BACKUP="${DING_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$DING_FILE" "$BACKUP"
echo "$BACKUP" > "$LOG_DIR/last_backup.txt"
log OK "Backup saved: $BACKUP"

python3 << PYEOF
import re, sys

with open('$DING_FILE') as f:
    c = f.read()

patch = """
        // PATCH_CREATE_FILE_HERE
        if (!this._createFileHerePatched) {
            this._createFileHerePatched = true;
            let _createItem = new Gtk.MenuItem({label: 'Create a file here...'});
            _createItem.connect('activate', () => {
                let _path = DesktopIconsUtil.getDesktopDir().get_path();
                GLib.spawn_async(
                    null,
                    ['$MAIN_SCRIPT', _path],
                    null,
                    GLib.SpawnFlags.DEFAULT,
                    null
                );
            });
            _createItem.show();
            this._menu.append(_createItem);
        }
        // END_PATCH
"""

match = re.search(r'(_prepareMenu\s*\(\s*\)\s*\{)', c)
if not match:
    print("[ERROR] _prepareMenu() not found in desktopManager.js")
    sys.exit(1)

start = match.end()
depth = 1
i = start
while i < len(c) and depth > 0:
    if c[i] == '{': depth += 1
    elif c[i] == '}': depth -= 1
    i += 1
close = i - 1

c = c[:close] + patch + c[close:]

with open('$DING_FILE', 'w') as f:
    f.write(c)
print("  Patch injected into _prepareMenu()")
PYEOF

log OK "DING patch applied (GLib.spawn_async, argv-safe)"

log INFO "Writing installation manifest..."
cat > "$LOG_DIR/installed_files.txt" << MANIFEST
MAIN_SCRIPT=$MAIN_SCRIPT
NAUTILUS_EXT=$NAUTILUS_EXT_DIR/create_file_here.py
DING_FILE=$DING_FILE
REAL_USER=$REAL_USER
REAL_HOME=$REAL_HOME
MANIFEST
log OK "Manifest written: $LOG_DIR/installed_files.txt"

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

DING_VERSION=$(grep -m1 '"version"' \
    /usr/share/gnome-shell/extensions/ding@rastersoft.com/metadata.json \
    2>/dev/null | tr -d ' "version:,' || echo "unknown")
{
    echo "================================================================"
    echo "  Installation completed : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  DING version patched   : $DING_VERSION"
    echo "  Backup                 : $BACKUP"
    echo "================================================================"
} >> "$LOG_FILE"

echo ""
echo "================================================================"
echo "                     Installation complete                      "
echo "================================================================"
echo ""
echo "  Folders (Nautilus)  -- Right-click -> 'Create a file here...'  [active now]"
echo "  Desktop  (DING)     -- Right-click -> 'Create a file here...'  [needs reboot]"
echo ""
echo "  Log file : $LOG_FILE"
echo ""
echo "  To uninstall:"
echo "    sudo ./right_click_file_uninstall.sh"
echo ""
echo "----------------------------------------------------------------"
warning "A reboot is required for the desktop right-click to become active."
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