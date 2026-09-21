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

Then install the privileged helper once. The charge controls need it; everything else works without:

```bash
sudo ~/.config/omarchy/plugins/cesarho.xps-power/system/install.sh
```

Read [`system/`](system/) first, since it runs as root.

Update later with `omarchy plugin update cesarho.xps-power`. Re-run `install.sh` afterwards if `system/`
changed.

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
runs anything from it as root: anything running as you could swap the script there and get root the next time
you approve a prompt. Instead `system/install.sh` (run by you, with `sudo`) copies a single helper to
`/usr/local/libexec/xps-power/`, owned by root, and adds a polkit action for it. The widget calls
`pkexec` on that fixed path and passes only a mode (`Fast`, `Standard`, `Adaptive`, `Custom`) or a limit
(`60`, `80`, `90`, `100`). The helper checks these against the same allowlist itself, uses fixed sysfs paths, and
ignores everything else. You still get a normal authentication prompt each time.

| File | Runs as | Does |
| --- | --- | --- |
| `system/xps-power-battery-set` | root (`pkexec`, installed copy) | writes `charge_types` and the start/end thresholds |
| `system/com.cesarho.xps-power.policy` | polkit | ties the action to the installed helper path |
| `system/install.sh` | root (`sudo`, run by you) | installs the two files above |
| `bin/omarchy-battery-mode-get` | you | reads `charge_types` |
| `bin/omarchy-battery-threshold-get` | you | reads the thresholds |

The installer copies from the plugin folder, so review `system/` right before you run it. To remove the helper, run
`sudo system/install.sh --uninstall`.

## License

MIT
