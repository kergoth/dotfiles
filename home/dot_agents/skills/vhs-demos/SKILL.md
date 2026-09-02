---
name: vhs-demos
description: >
  Reference for recording terminal demo GIFs with VHS (charmbracelet/vhs).
  Use whenever the user wants to record, demo, or show off a CLI tool or workflow:
  "make a demo gif", "record this", "show X in action", "create a terminal animation",
  "make a demo for the PR", "capture this workflow", or any request to produce a GIF
  or MP4 of a terminal session. Also use when the user is already writing a .tape file
  and hits a VHS-specific issue (timing, sizing, Hide/Show, colors, stubs).
---

# VHS Demo Recording

VHS records terminal sessions into GIF/MP4 by executing commands in a
pseudo-terminal and capturing frames.

## Gotchas

**Width/Height are pixels, not columns.** `Set Width 100` produces a
120×120 minimum-dimension error. Use pixel values: `1200×600` is a reasonable
default for a readable widescreen GIF.

**`Hide` does not erase scrollback.** Commands in a `Hide` block still run and
their output sits in the terminal buffer. Add `Ctrl+L` (or `Type "clear"; Enter`
as a fallback) followed by `Sleep 200ms` at the end of the `Hide` block before
`Show`, or setup commands bleed into the recording. `Ctrl+L` is preferred: it
clears the visible screen in one line with no typing animation artifact.

**`Read` on a GIF shows only the first frame.** To verify what the recording
looks like at the end, extract the last frame with ffmpeg:
```bash
COUNT=$(ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=nb_read_frames -of csv=p=0 demo.gif 2>/dev/null)
ffmpeg -i demo.gif -vf "select='eq(n\,$((COUNT-1)))'" -vsync 0 /tmp/last.png -y
```
Then `Read /tmp/last.png`.

**Color PS1 needs readline width guards.** Without `\001...\002` wrappers the
cursor position is miscalculated and the prompt wraps incorrectly. Use a
sourced setup script rather than inline tape escaping:
```bash
# demo-env.sh
export PS1=$'\001\e[1;32m\002myproject\001\e[0m\002 \$ '
```

**`Sleep` timing is recording time, not playback time.** Set `Sleep` values to
cover real command execution. `PlaybackSpeed` compresses the recorded frames in
post — it does not affect what gets recorded.

## Timing strategy

1. **Try `Set PlaybackSpeed N` first.** It compresses the whole GIF uniformly
   with no other changes. If the ratio between fast and slow operations is
   acceptable at the chosen multiplier, you're done. `PlaybackSpeed 2.0`–`3.0`
   covers most cases where one step is moderately slow.

2. **Use stubs when the ratio is unworkable.** If a 1s git fetch and a 60s AI
   analysis both need to look natural, no single `PlaybackSpeed` value works.
   Create stub executables in a temp directory and prepend to `PATH` via the
   setup script. Stubs must emit the exact stderr messages the real tool would
   produce — silent stubs misrepresent behavior.

3. **Measure real durations first.** Run the commands outside vhs and note wall
   time. Set tape `Sleep` values to `real_time × 1.3` plus a 3–4s tail pause
   on the final command so output is fully visible when the GIF ends.

4. **`Type@Xms` overrides typing speed per command** without changing the global
   `Set TypingSpeed`. Useful for one-off adjustments.

## Minimal tape template

```tape
Output demo.gif
Set FontSize 14
Set Width 1200
Set Height 600
Set Theme "Dracula"
Set TypingSpeed 80ms
# Set PlaybackSpeed 2.0  # uncomment to compress uniformly

Hide
Type "cd /path/to/project && source demo-env.sh"
Enter
Sleep 300ms
Ctrl+L
Sleep 200ms
Show

Sleep 500ms
Type "your-command --flag arg"
Sleep 100ms
Enter
Sleep Xs   # cover real execution time × 1.3, plus tail pause
```

## Stub pattern

```bash
# demo-env.sh — also sets up PATH for stubs
export PS1=$'\001\e[1;32m\002myproject\001\e[0m\002 \$ '

mkdir -p /tmp/demo-bin
cat > /tmp/demo-bin/slow-tool << 'EOF'
#!/usr/bin/env bash
# emit the real tool's stderr messages, sleep a representative duration
printf 'Fetching data...\n' >&2
sleep 6
printf 'result-output\n'   # stdout the caller expects
EOF
chmod +x /tmp/demo-bin/slow-tool
export PATH="/tmp/demo-bin:$PATH"
```

## GitHub embedding

Drag the GIF into the PR description textarea. GitHub uploads it to their CDN
and inserts an `![image](https://github.com/user-attachments/assets/...)` link
automatically — no external hosting needed.
