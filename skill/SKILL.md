---
name: askpass-prompt
description: Run commands that need sudo on Ubuntu/Linux by popping up the desktop's own password dialog (polkit, falling back to zenity) for the user instead of failing on "a terminal is required" or "a password is required". Use whenever a shell command needs root (apt install, systemctl, editing /etc, chown, mount, ufw, docker setup) and `sudo -n true` fails. Linux desktop sessions only. Also for /askpass-prompt <command>.
argument-hint: "<command to run as root>"
---

# askpass-prompt

Your shell has no terminal, so plain `sudo` cannot ask for a password. `${CLAUDE_SKILL_DIR}/scripts/gsudo` opens a password dialog on the user's screen instead. When a polkit agent is running (GNOME and most desktops), it uses `pkexec`, which shows the system's own authentication dialog. Otherwise it runs `sudo -A` with a zenity dialog. The password goes from the dialog straight to the system; you never see it.

Under pkexec the command runs in your current directory but with a clean environment (`HOME=/root`, a default `PATH`). Pass any variables the command needs explicitly, for example `gsudo env DEBIAN_FRONTEND=noninteractive apt-get install -y nginx`.

## How to run a root command

1. Ask the user in one line before anything that changes the system, unless they already asked for that exact action. Say what the command does.
2. Run it through gsudo, the same way you would use sudo:

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/gsudo" apt-get install -y ripgrep
   ```

3. Before the call, tell the user a password dialog is about to appear. The dialog shows the command so they can check it (under pkexec it appears as `/usr/bin/env --chdir=<dir> <command>`).
4. Give the Bash call a long timeout (at least 180000 ms), because it waits for the user to type.

The dialog appears once per gsudo call, because sudo's cached login does not carry across your separate shells. When several commands need root, put them in one call:

```bash
"${CLAUDE_SKILL_DIR}/scripts/gsudo" bash -c 'apt-get update && apt-get install -y nginx && systemctl enable --now nginx'
```

If sudo is already authorized (NOPASSWD or a cached login), gsudo skips the dialog.

## Results

| What you see | Meaning | What to do |
|---|---|---|
| Command output, exit 0 | Worked | Continue |
| `Request dismissed` / exit 126 (pkexec), or `sudo: no password was provided` (zenity) | User pressed Cancel | Stop and ask the user; do not retry on your own |
| `Not authorized` / exit 127 (pkexec), or `3 incorrect password attempts` (zenity) | Wrong password or not allowed | Tell the user and stop |
| `env: '...': No such file or directory` | Command not on pkexec's default `PATH` | Use the full path to the program |
| `askpass: no zenity, yad or kdialog found` | No dialog program | Ask the user to run `! sudo apt install zenity` |
| Dialog never appears and the call times out | No desktop session (SSH, headless server) | Tell the user to run the command themselves with `! sudo <command>` |

## Rules

- Never ask the user to type their password into the chat, and never echo, store or pipe a password yourself (`echo pw | sudo -S` is not allowed).
- Do not edit `/etc/sudoers` or add NOPASSWD rules unless the user asks for it directly.
- One purpose per call. Do not tack unrelated root commands onto a call the user approved for something else.
