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

Update later with `omarchy plugin update cesarho.xps-power`.

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

Changing the charge mode or limit needs root, so the widget runs one of the scripts in [`bin/`](bin/)
through `pkexec`. You get a normal authentication prompt each time. These scripts are read from the plugin
folder in your home directory, so anything that can write there can change what runs as root once you approve
a prompt. Review them:

| Script | Runs as | Does |
| --- | --- | --- |
| `omarchy-battery-mode-set` | root (`pkexec`) | writes `charge_types` |
| `omarchy-battery-threshold-set` | root (`pkexec`) | writes the start/end thresholds and `charge_types` |
| `omarchy-battery-mode-get` | you | reads `charge_types` |
| `omarchy-battery-threshold-get` | you | reads the thresholds |

## License

MIT
