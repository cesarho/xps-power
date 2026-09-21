# XPS Power

An [Omarchy](https://omarchy.org) bar widget for Dell XPS laptops. It is a fork of the built-in
`omarchy.power` widget with battery charge controls added.

- Battery level, time left / time to full, and system stats
- Power profile switcher
- **Charge mode**: Fast, Standard, Adaptive or Custom (Dell's `charge_types`)
- **Charge limit**: stop charging at 60, 80, 90 or 100%

## Install

```bash
omarchy plugin add https://github.com/cesarho/xps-power.git --enable
```

Enabling it replaces the stock Power widget in your bar, in the same spot. Omarchy does this for any
plugin that declares `omarchy.clonedFrom`. The keybinding and menu items that target `omarchy.power`
also go to this widget. To go back to the stock widget, run `omarchy plugin disable cesarho.xps-power`.

Then install the privileged helper once. The charge controls need it; everything else works without it.
Until it's installed, the panel shows this command with a button to copy it:

```bash
~/.config/omarchy/plugins/cesarho.xps-power/system/install.sh
```

Run it as your regular user; it asks for your password through `sudo`. It needs network access. Read
[`system/`](system/) first, since the helper runs as root.

Update later with `omarchy plugin update cesarho.xps-power`. Re-run `install.sh` afterwards if `system/`
changed.

After adding, updating or re-adding the plugin, restart the shell:

```bash
omarchy restart shell
```

The shell reloads the plugin folder on its own but can keep the previous `Panel.qml` in memory. Until you
restart, the widget may run old code. For example, after an update that moved a script, the charge controls
fail with an error.

## Requirements

The charge controls use the kernel's battery sysfs files and only work on laptops that expose them,
which in practice means Dell laptops with the `dell-wmi-sysman` / `dell-laptop` drivers:

- `/sys/class/power_supply/BAT*/charge_control_end_threshold`
- `/sys/class/power_supply/BAT*/charge_control_start_threshold`
- `/sys/class/power_supply/BAT*/charge_types`

On other hardware the battery, profile and stats parts still work, but the charge rows will do nothing.
The start threshold is clamped to 50-95% to match the limits the Dell BIOS enforces.

## Security

The plugin runs inside the `omarchy-shell` process without a sandbox, so read the code before you enable it.

Changing the charge mode or limit needs root. The plugin folder is writable by your user, so the widget never
runs anything from it as root: anything running as you could swap a script there and get root. Instead
`system/install.sh` installs a single helper to `/usr/local/libexec/xps-power/`, owned by root, and adds a polkit
action for it. Root never reads the plugin folder during the install: it downloads both files from this GitHub repo,
pinned to the commit your checkout is on. The widget calls `pkexec` on that fixed path and passes only a mode
(`Fast`, `Standard`, `Adaptive`, `Custom`) or a limit (`60`, `80`, `90`, `100`). The helper checks these against the
same allowlist itself, uses fixed sysfs paths, and ignores everything else.

Because the helper can do nothing but set one of those 8 values, the polkit action lets the active local session
run it without a password prompt. Remote and inactive sessions still need an admin password.

| File | Runs as | Does |
| --- | --- | --- |
| `system/xps-power-battery-set` | root (`pkexec`, installed copy) | writes `charge_types` and the start/end thresholds |
| `system/com.cesarho.xps-power.policy` | polkit | ties the action to the installed helper path |
| `system/install.sh` | you (downloads and installs through `sudo`) | installs the two files above |
| `bin/omarchy-battery-mode-get` | you | reads `charge_types` |
| `bin/omarchy-battery-threshold-get` | you | reads the thresholds |

To remove the helper, run `system/install.sh --uninstall`.

## License

MIT
