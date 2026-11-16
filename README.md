# askpass-prompt

A Claude Code skill for Ubuntu (and other Linux desktops). When the agent needs `sudo`, an authentication dialog pops up on your screen instead of the command failing and you having to run it yourself in another terminal.

## How it works

- `skill/scripts/gsudo <cmd>` runs the command as root and asks for your password on screen. The agent never sees the password.
- If a polkit agent is running (GNOME Shell on stock Ubuntu, and most other desktops), it uses `pkexec`, so you get the system's own authentication dialog, the same one you see when installing software. The command keeps its working directory but runs with a clean environment.
- Otherwise it runs `sudo -A` with `SUDO_ASKPASS` pointing at `skill/scripts/askpass`, which opens a `zenity --password` dialog (falls back to `yad`, then `kdialog`) showing the command. It finds the Wayland/X11 display on its own if the agent's shell lost `DISPLAY`/`WAYLAND_DISPLAY`.
- Force one or the other with `ASKPASS_PROMPT_MODE=pkexec` or `ASKPASS_PROMPT_MODE=zenity`.

## Face and fingerprint login

Nothing to configure here: the dialog authenticates through PAM, the same stack as `sudo` and the login screen. If the machine has [Howdy](https://github.com/boltgolt/howdy) (IR camera face login) or `fprintd` enabled in `/etc/pam.d/common-auth`, the agent's root commands can be approved by looking at the camera or touching the sensor, and fall back to the password when the scan fails.

- pkexec uses the `polkit-1` PAM service (`/etc/pam.d/polkit-1`, or `/usr/lib/pam.d/polkit-1` on newer Ubuntu), which includes `common-auth`, where Howdy and fprintd add themselves.
- The zenity fallback goes through `sudo`, which also uses `common-auth`: the scan runs first, and the password dialog only appears if it fails.
- Howdy skips itself over SSH (`abort_if_ssh`) and with the lid closed (`abort_if_lid_closed`), so you get the password prompt there.

## Install

```bash
sudo apt install zenity   # already present on stock Ubuntu desktop
git clone https://github.com/sonnnty/askpass-prompt.git
cd askpass-prompt && ./install.sh
```

`install.sh` symlinks `skill/` into `~/.claude/skills/askpass-prompt` (and any `~/.claude-*` config dirs). Restart Claude Code, then the agent picks it up when a command needs root, or call it yourself with `/askpass-prompt <command>`.

You can also use `gsudo` directly from any tool or script: `skill/scripts/gsudo apt-get update`.

## Notes

- The dialog appears once per `gsudo` call: pkexec never caches, and sudo caches per terminal while each agent command runs in a fresh shell. The skill tells the agent to batch root commands into one call.
- Needs a desktop session. Over SSH or on a headless server there is no screen to show the dialog on.
