---
name: askpass-prompt
description: Run commands that need sudo on Ubuntu/Linux by popping up a desktop password dialog (zenity) for the user instead of failing on "a terminal is required" or "a password is required". Use whenever a shell command needs root (apt install, systemctl, editing /etc, chown, mount, ufw, docker setup) and `sudo -n true` fails. Linux desktop sessions only. Also for /askpass-prompt <command>.
argument-hint: "<command to run as root>"
---

# askpass-prompt

Your shell has no terminal, so plain `sudo` cannot ask for a password. `${CLAUDE_SKILL_DIR}/scripts/gsudo` runs `sudo -A` with a `SUDO_ASKPASS` helper that opens a password dialog on the user's screen. The password goes from the dialog straight to sudo; you never see it.

## How to run a root command

1. Ask the user in one line before anything that changes the system, unless they already asked for that exact action. Say what the command does.
2. Run it through gsudo, the same way you would use sudo:

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/gsudo" apt-get install -y ripgrep
   ```

3. Before the call, tell the user a password dialog is about to appear. The dialog shows the command so they can check it.
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
| `sudo: no password was provided` / exit 1 right after the dialog | User pressed Cancel | Stop and ask the user; do not retry on your own |
| `Sorry, try again` then `3 incorrect password attempts` | Wrong password three times | Tell the user and stop |
| `askpass: no zenity, yad or kdialog found` | No dialog program | Ask the user to run `! sudo apt install zenity` |
| Dialog never appears and the call times out | No desktop session (SSH, headless server) | Tell the user to run the command themselves with `! sudo <command>` |

## Rules

- Never ask the user to type their password into the chat, and never echo, store or pipe a password yourself (`echo pw | sudo -S` is not allowed).
- Do not edit `/etc/sudoers` or add NOPASSWD rules unless the user asks for it directly.
- One purpose per call. Do not tack unrelated root commands onto a call the user approved for something else.
