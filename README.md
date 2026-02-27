# Right Click File

Ubuntu with GNOME/Nautilus does not natively offer a way to create a file directly from the desktop or a folder without going through the CLI or the template system, a workflow that can be unfamiliar, especially for users coming from Windows where right-clicking to create a new file is standard.

**Right Click File** bridges that gap by bringing the same convenience to GNOME, making the transition smoother, the daily workflow faster for everyone and facilitating linux adoption.

> [!NOTE]
> Designed for Ubuntu 20.04, 22.04 and 24.04 running GNOME with Nautilus as the file manager and the DING extension for desktop icons. Other Debian-based distributions with the same stack may work but are not officially supported yet.

The feature adds:
- a **"Create a file here..."** entry to the right-click context menu on the desktop and in all Nautilus folders
- a dialog showing the **full target path** and a field to name the file
- automatic opening of the created file with your **default text editor**

---

## How it works

<a href="https://ibb.co/yF4xB5vW"><img src="https://i.ibb.co/1Gz4JKy8/right-click-file-demo.gif" alt="right-click-file-demo" border="0"></a>

---

## Installation

### Via package (recommended)

Download the latest `.deb` from the [releases page](https://github.com/sypher93/right-click-file/releases) or via `wget`:
```bash
wget -P /tmp https://github.com/sypher93/right-click-file/releases/latest/download/right-click-file_1.0.0_all.deb
```
> [!TIP]
> Using `-P /tmp` downloads directly into `/tmp`, avoiding the `apt` sandbox warning in a single step.

Then :

```bash
sudo apt install /tmp/right-click-file_1.0.0_all.deb
```

Dependencies installed automatically: `zenity`, `xdg-utils`, `python3-nautilus`.

### Via script

Install:
```bash
curl -fsSL https://github.com/sypher93/right-click-file/raw/main/scripts/right_click_file.sh -o right_click_file.sh
sudo bash right_click_file.sh
```

Uninstall:
```bash
curl -fsSL https://github.com/sypher93/right-click-file/raw/main/scripts/right_click_file_uninstall.sh -o right_click_file_uninstall.sh
sudo bash right_click_file_uninstall.sh
```

> [!WARNING]
> For both options, a reboot is required after installation for the desktop right-click entry to become active. The Nautilus folder entry is available immediately.

---

## Uninstall package

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

## License

GNU General Public License v3.0 -- see [LICENSE](https://www.gnu.org/licenses/gpl-3.0.html) for details.