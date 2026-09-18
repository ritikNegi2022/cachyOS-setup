# tmux Tutorial — From Zero to Productive

tmux is a **terminal multiplexer**: one terminal window that holds many
terminals. Close your terminal, reboot your editor, lose SSH — everything
keeps running. Reattach later, exactly where you left off.

Your setup: `Ctrl+Space` prefix, vim keys, monochrome bar, no plugins.
Config lives at `~/.config/tmux/tmux.conf` (vendored in the setup repo as
`configs/tmux.conf` — `prefix+r` reloads it after edits).

---

## 1. The mental model (read this once)

```
┌─ tmux server (runs in background, survives terminal close) ─┐
│  ┌─ session "work" ─────────────────────────────────────┐  │
│  │  ┌─ window 1: editor ─────────┬─ window 2: server ───┐ │  │
│  │  │ ┌─ pane ────┐ ┌─ pane ───┐ │ │ single pane        │ │  │
│  │  │ │ hx .      │ │ lazygit  │ │ │ npm run dev        │ │  │
│  │  │ └───────────┘ └──────────┘ │ │                    │ │  │
│  │  └────────────────────────────┴──────────────────────┘ │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌─ session "notes" ────────────────────────────────┐       │
│  │  ┌─ window 1 ──┐                                 │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

- **Server** — one per user, holds everything. Dies only on reboot/logout.
- **Session** — a project workspace (`work`, `notes`, `server`). You *attach*
  to one at a time; the rest keep running headless.
- **Window** — like a browser tab inside a session (numbered from **1** here).
- **Pane** — a split inside a window.

You always look at **one pane** of **one window** of **one session**.
Everything else keeps running.

---

## 2. The prefix key (the one thing to learn first)

Almost every tmux command starts with the **prefix**: hold `Ctrl`, tap
`Space`, release both, then tap the command key.

- New window → `Ctrl+Space`, release, then `c`
- Split vertically → `Ctrl+Space`, release, then `|`
- Detach → `Ctrl+Space`, release, then `d`

Notation in this doc: `prefix+c` means the sequence above.
To send a literal `Ctrl+Space` to the app inside (rare — nested tmux over
SSH), press `prefix` twice.

---

## 3. Sessions — projects that never die

| What | Keys / command |
|---|---|
| New named session | `tmux new -s work` (from terminal) |
| Attach-or-create (best daily driver) | `tm` (shell helper: `tm work` attaches or creates) — or inside tmux: `prefix+S`, type name, Enter |
| Pick a session visually | `prefix+s` |
| List sessions | `tmux ls` (from terminal) |
| Detach (leave everything running) | `prefix+d` |
| Reattach | `tmux attach -t work` (or `tm` with no args → `default` session) |
| Kill a session | `tmux kill-session -t notes` (from terminal), or inside it: `prefix+:` then type `kill-session`, Enter |

**The survival rule:** detaching, closing the terminal, even losing
Wi-Fi on SSH — sessions keep running. **Reboot** kills them (they live in
RAM). `prefix+d` before you walk away; `tm work` when you return.

---

## 4. Windows — tabs for one project

| What | Keys |
|---|---|
| New window (opens in current folder) | `prefix+c` |
| Next / previous window | `Shift+Left` / `Shift+Right` (no prefix!) or `prefix+n` / `prefix+p` |
| Jump to window N | `prefix+1` … `prefix+9` |
| Rename window | `prefix+,` |
| Close window (asks first) | `prefix+&` |
| Pick from list | `prefix+w` |

Windows auto-renumber from 1 when one closes, and each shows its current
folder name (`~/projects/myapp` shows as `myapp`) until a program renames it.

---

## 5. Panes — splits inside a window

| What | Keys |
|---|---|
| Split side-by-side | `prefix+\|` |
| Split top/bottom | `prefix+-` |
| Move between panes | `Alt+h/j/k/l` (no prefix!) or `prefix+h/j/k/l` |
| Resize (repeatable — hold prefix, tap repeatedly) | `prefix+H/J/K/L` (5 cells a tap) |
| Zoom pane fullscreen / back | `prefix+z` |
| Close pane (asks first) | `prefix+x` |
| Mouse: click to focus, drag borders to resize, scroll to browse | always on |

New splits inherit the current pane's folder, so `hx .` + `prefix+|` +
`npm run dev` just works without `cd`-ing.

> Note: `Alt+h/j/k/l` is grabbed by tmux even inside Neovim/Helix — the
> standard trade-off for prefix-less navigation. Inside editors, keep using
> their own split keys (`<leader>sv` / `<leader>sh` in nvim).

---

## 6. Copy mode — scroll, search, copy with vim keys

Terminal scrollback is a tmux job, not the terminal's:

| What | Keys |
|---|---|
| Enter copy mode | `prefix+[` |
| Move | `h/j/k/l`, arrows, `PgUp/PgDn`, `g` top, `G` bottom |
| Search forward / backward | `/` / `?`, then `n` / `N` for next/previous hit |
| Start selection | `v` (or `Ctrl+v` for block/column select) |
| Yank to system clipboard + quit | `y` (paste anywhere with `Super+v`) |
| Quit without copying | `q` or `Esc` |
| Paste inside tmux | `prefix+]` |

Search is incremental — matches highlight as you type. `y` copies via
`xclip`, so it lands in the same clipboard as everything else on this
system. Scrollback holds 50,000 lines per pane.

---

## 7. Your bar, your rules

The bottom bar is one monochrome line: session name (left), windows
(center), clock (right).

| What | Keys |
|---|---|
| Hide / show the bar (zen-style) | `prefix+b` |
| Reload config after editing it | `prefix+r` |

---

## 8. Five 5-minute drills (do these once, keep the skill forever)

1. **Survive a disconnect:** `tmux new -s drill`, run `sleep 300`, `prefix+d`,
   close the terminal, open a new one, `tmux attach -t drill` — still counting.
2. **Editor + server:** in `work`: `hx .`, `prefix+|`, `npm run dev`,
   `Alt+h`/`Alt+l` to hop. `prefix+z` to zoom the editor, `prefix+z` back.
3. **Grab an error:** run something verbose, `prefix+[`, `/error`, `n` through
   hits, `v` + `y` to yank one into the clipboard.
4. **Two projects:** `prefix+S`, type `notes`, Enter. `prefix+s` flips between
   `work` and `notes`. `tmux ls` shows both.
5. **Clean exit:** `tmux kill-session -t drill`. (Killing the shell with `exit`
   in the last pane of the last window ends the session too.)

---

## 9. Full keybinding cheat sheet

Prefix is `Ctrl+Space`. Keys marked *(no prefix)* work bare.

### Sessions
| Keys | Action |
|---|---|
| `prefix+S` | New session prompt (attaches if name exists) |
| `prefix+s` | Session picker |
| `prefix+d` | Detach (everything keeps running) |
| `prefix+:` `kill-session` | Kill current session |
| `tm [name]` / `tmux ls` / `tmux attach -t NAME` | Shell-side session helpers |

### Windows
| Keys | Action |
|---|---|
| `prefix+c` | New window in current folder |
| `Shift+Left` / `Shift+Right` *(no prefix)* | Previous / next window |
| `prefix+n` / `prefix+p` | Next / previous window |
| `prefix+1`–`prefix+9` | Jump to window |
| `prefix+,` | Rename window |
| `prefix+&` | Kill window (confirms) |
| `prefix+w` | Window picker |

### Panes
| Keys | Action |
|---|---|
| `prefix+\|` | Split side-by-side (same folder) |
| `prefix+-` | Split top/bottom (same folder) |
| `Alt+h/j/k/l` *(no prefix)* | Focus pane |
| `prefix+h/j/k/l` | Focus pane |
| `prefix+H/J/K/L` | Resize 5 cells (repeatable) |
| `prefix+z` | Zoom fullscreen / back |
| `prefix+x` | Kill pane (confirms) |

### Copy mode (`prefix+[` to enter)
| Keys | Action |
|---|---|
| `h/j/k/l`, arrows, `PgUp/PgDn`, `g`/`G` | Move |
| `/`, `?`, `n`, `N` | Search forward/backward, next/previous hit |
| `v` / `Ctrl+v` | Start selection / block selection |
| `y` | Yank to system clipboard + quit |
| `q` / `Esc` | Quit |
| `prefix+]` | Paste |

### Misc
| Keys | Action |
|---|---|
| `prefix+b` | Toggle status bar |
| `prefix+r` | Reload config |
| `prefix+?` | Show every keybinding |
| `prefix+:` | Command prompt (any `tmux` command) |

---

## 10. Troubleshooting

- **Weird colors in nvim/helix inside tmux:** the config forces
  `tmux-256color` + truecolor. If an app looks off, check `echo $TERM`
  inside tmux prints `tmux-256color`. Outside tmux it should be
  `xterm-256color`/`alacritty`.
- **`y` doesn't reach the clipboard:** needs `xclip` (installed by setup).
  Over SSH without X forwarding, it copies on the *remote* side instead.
- **ESC feels laggy in vim:** `escape-time 0` in this config fixes it. If you
  ever feel a delay, confirm no other config overrides it:
  `tmux show -g escape-time`.
- **Prefix does nothing / types a space:** another program ate `Ctrl+Space`
  (IME, browser). Use a plain terminal; inside tmux-over-SSH press prefix
  twice for the inner session.
- **"No server running":** you have no sessions — `tm` to start one. After a
  **reboot** all sessions are gone by design; `tm work` recreates.
- **Pane is stuck in copy mode:** `q`.
- **Lost, everything is weird:** `prefix+?` lists keys; `tmux ls` lists
  sessions from a fresh terminal; worst case `tmux kill-server` resets all
  (kills everything running inside — last resort).
