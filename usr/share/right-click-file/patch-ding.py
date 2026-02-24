import re, sys

DING_FILE = "/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/desktopManager.js"
SCRIPT = "/usr/local/bin/create-file-here.sh"
PATCH_START = "// PATCH_CREATE_FILE_HERE"
PATCH_END = "// END_PATCH"

PATCH = """
        // PATCH_CREATE_FILE_HERE
        if (!this._createFileHerePatched) {
            this._createFileHerePatched = true;
            let _createItem = new Gtk.MenuItem({label: 'Create a file here...'});
            _createItem.connect('activate', () => {
                let _path = DesktopIconsUtil.getDesktopDir().get_path();
                GLib.spawn_async(
                    null,
                    ['""" + SCRIPT + """', _path],
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

def apply():
    with open(DING_FILE) as f:
        c = f.read()

    c = re.sub(
        r'\s*// PATCH_CREATE_FILE_HERE.*?// END_PATCH\n',
        '\n', c, flags=re.DOTALL
    )

    match = re.search(r'(_prepareMenu\s*\(\s*\)\s*\{)', c)
    if not match:
        print("[ERROR] _prepareMenu() not found", file=sys.stderr)
        sys.exit(1)

    start = match.end()
    depth, i = 1, start
    while i < len(c) and depth > 0:
        if c[i] == '{': depth += 1
        elif c[i] == '}': depth -= 1
        i += 1
    close = i - 1

    c = c[:close] + PATCH + c[close:]
    with open(DING_FILE, 'w') as f:
        f.write(c)
    print("[OK] Patch applied to _prepareMenu()")

def remove():
    with open(DING_FILE) as f:
        c = f.read()

    if PATCH_START not in c:
        print("[INFO] No patch found, nothing to remove.")
        return

    c = re.sub(
        r'\s*// PATCH_CREATE_FILE_HERE.*?// END_PATCH\n',
        '\n', c, flags=re.DOTALL
    )
    with open(DING_FILE, 'w') as f:
        f.write(c)
    print("[OK] Patch removed from _prepareMenu()")

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("apply", "remove"):
        print("Usage: patch-ding.py [apply|remove]", file=sys.stderr)
        sys.exit(1)
    apply() if sys.argv[1] == "apply" else remove()
