import gi, subprocess, os

for _v in ['4.0', '3.0']:
    try:
        gi.require_version('Nautilus', _v)
        break
    except Exception:
        pass

from gi.repository import Nautilus, GObject

SCRIPT = "/usr/local/bin/create-file-here.sh"

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
