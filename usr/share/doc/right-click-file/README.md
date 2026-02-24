# right-click-file

GNOME Ubuntu does not natively offer a way to create a file directly from the desktop or a folder without going through the CLI or the template system, a workflow that can be unfamiliar, especially for users coming from Windows where right-clicking to create a new file is standard. 

**Right Click File** bridges that gap by bringing the same convenience to GNOME, making the transition smoother and the daily workflow faster for everyone.

The feature adds:
- a **"Create a file here..."** entry to the right-click context menu on the desktop and in all Nautilus folders
- a dialog showing the **full target path** and a field to name the file
- automatic opening of the created file with your **default text editor**

> [!NOTE]
> Compatible with Ubuntu 20.04, 22.04 and 24.04 running GNOME with the DING desktop extension.

---

## Installation

```bash
sudo apt install ./right-click-file_1.0.0_all.deb
```

Dependencies installed automatically: `zenity`, `xdg-utils`, `python3-nautilus`.

> [!WARNING]
> A reboot is required after installation for the desktop right-click entry to become active. The Nautilus folder entry is available immediately.

---

## How it works

| Location | How to access |
|---|---|
| Any open folder | Right-click on background -> Create a file here... |
| Selected folder | Right-click on folder icon -> Create a file here... |
| Desktop | Right-click on background -> Create a file here... |

---

## Uninstall

```bash
sudo apt remove right-click-file
```

To also remove logs:

```bash
sudo apt purge right-click-file
```

> [!NOTE]
> A reboot is required after removal for the desktop right-click entry to disappear.

---

## Logs

Installation and removal events are logged to:

```
/var/log/right_click_file/install.log
```

---

## Author

**sypher93** -- [github.com/sypher93](https://github.com/sypher93)

## License

GNU General Public License v3.0 -- see [LICENSE](https://www.gnu.org/licenses/gpl-3.0.html) for details.
