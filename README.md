# askpass-prompt

A Claude Code skill for Ubuntu (and other Linux desktops). When the agent needs `sudo`, a password dialog pops up on your screen instead of the command failing and you having to run it yourself in another terminal.

## How it works

- `skill/scripts/gsudo <cmd>` runs `sudo -A <cmd>` with `SUDO_ASKPASS` pointing at `skill/scripts/askpass`.
- `askpass` opens a `zenity --password` dialog (falls back to `yad`, then `kdialog`) showing the command being run, and hands what you type straight to sudo. The agent never sees the password.
- It finds the Wayland/X11 display on its own if the agent's shell lost `DISPLAY`/`WAYLAND_DISPLAY`.

## Install

```bash
sudo apt install zenity   # already present on stock Ubuntu desktop
git clone https://github.com/sonnnty/askpass-prompt.git
cd askpass-prompt && ./install.sh
```

`install.sh` symlinks `skill/` into `~/.claude/skills/askpass-prompt` (and any `~/.claude-*` config dirs). Restart Claude Code, then the agent picks it up when a command needs root, or call it yourself with `/askpass-prompt <command>`.

You can also use `gsudo` directly from any tool or script: `skill/scripts/gsudo apt-get update`.

## Notes

- The dialog appears once per `gsudo` call. sudo caches your login per terminal, and each agent command runs in a fresh shell, so the cache does not carry over. The skill tells the agent to batch root commands into one call. If you want a single prompt to cover several minutes, you can add `Defaults:YOUR_USER timestamp_type=global` with `sudo visudo`; this weakens isolation between terminals, so it is off by default.
- Needs a desktop session. Over SSH or on a headless server there is no screen to show the dialog on.
