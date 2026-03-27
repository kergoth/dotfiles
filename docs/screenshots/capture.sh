#!/usr/bin/env bash
# Capture terminal gallery screenshots as PNGs using headless Chrome
# Usage: ./capture.sh [gallery.html]
#
# Generates:
#   shell-prompt.png
#   tmux-statusbar.png
#   claude-statusline-calm.png
#   claude-statusline-worktree.png
#   claude-statusline-ratelimit-ok.png
#   claude-statusline-ratelimit-warn.png
#   claude-statusline-critical.png
#   claude-statusline-both-limits.png
#   claude-statusline-sonnet.png

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GALLERY="${1:-$SCRIPT_DIR/terminal-gallery.html}"
OUTDIR="$SCRIPT_DIR"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [[ ! -x "$CHROME" ]]; then
    echo "Chrome not found at $CHROME" >&2
    exit 1
fi

if [[ ! -f "$GALLERY" ]]; then
    echo "Gallery HTML not found at $GALLERY" >&2
    exit 1
fi

# Read the shared <style> block from the gallery
STYLES=$(sed -n '/<style>/,/<\/style>/p' "$GALLERY")

# Helper: create a standalone HTML snippet and screenshot it
capture() {
    local name="$1"
    local body="$2"
    local width="${3:-900}"
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/screenshot-XXXXXX.html")

    cat > "$tmp" <<HTMLEOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
$STYLES
<style>
  body { padding: 16px 24px; display: inline-block; }
  .state-label:first-child { margin-top: 0; }
</style>
</head><body>$body</body></html>
HTMLEOF

    (cd "$OUTDIR" && "$CHROME" \
        --headless=new \
        --disable-gpu \
        --no-sandbox \
        --screenshot="$name.png" \
        --window-size="${width},900" \
        --default-background-color=0e0e16 \
        --force-device-scale-factor=2 \
        "file://$tmp" 2>/dev/null)

    rm -f "$tmp"
    echo "  $name.png"
}

echo "Capturing screenshots to $OUTDIR/"

# Shell prompt
capture "shell-prompt" '
<div class="terminal">
  <div class="terminal-titlebar">
    <div class="terminal-dot dot-red"></div>
    <div class="terminal-dot dot-yellow"></div>
    <div class="terminal-dot dot-green"></div>
    <div class="terminal-title">kitty — zsh</div>
  </div>
  <div class="terminal-body">
    <div><span class="prompt-dir">~/.dotfiles</span> <span class="prompt-git">main</span> <span class="prompt-clean">✔</span></div>
    <div><span class="prompt-char">❯</span> <span style="color:#f8f8f2">chezmoi apply</span></div>
    <div style="height:8px"></div>
    <div><span class="prompt-dir">~/Workspace/pano-ops/pano-ec</span> <span class="prompt-git">feature/async-uploads</span> <span class="prompt-dirty">!1</span></div>
    <div><span class="prompt-char">❯</span> <span style="color:#f8f8f2;opacity:0.4">█</span></div>
  </div>
</div>
'

# Tmux
capture "tmux-statusbar" '
<div class="bar tmux-bar">
  <span class="seg tmux-session"> dotfiles </span>
  <span class="seg tmux-win-inactive"> 0 |<span style="color:#bcbcbc"> zsh </span></span>
  <span class="seg tmux-win-active-bg"><span class="tmux-win-active-num"> 1 |</span><span class="tmux-win-active-name"> claude-code </span></span>
  <span class="seg tmux-win-inactive"> 2 |<span style="color:#bcbcbc"> nvim </span></span>
  <span class="tmux-spacer"></span>
  <span class="seg tmux-right-mid"> 2026-03-27 | 14:32 </span>
  <span class="seg tmux-right-host"> asano </span>
</div>
' 900

# Claude: calm
capture "claude-statusline-calm" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">.dotfiles</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg ctx-good"> ctx 21% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on · 1 shell</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: worktree
capture "claude-statusline-worktree" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-worktree">⊕ upload-retry</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">feature/retry-logic</span>
    <span class="tmux-spacer"></span>
    <span class="seg ctx-good"> ctx 35% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on · 3 shells</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: rate limit ok
capture "claude-statusline-ratelimit-ok" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">W/pano-o/pano-ec</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg rl-ok"> 5h ✓ 55% </span>
    <span style="width:4px"></span>
    <span class="seg ctx-good"> ctx 42% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: rate limit warning
capture "claude-statusline-ratelimit-warn" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">W/pano-o/pano-ec</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg rl-warn"> 5h ⚠ 62% ~1.2h </span>
    <span style="width:4px"></span>
    <span class="seg ctx-good"> ctx 45% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: critical
capture "claude-statusline-critical" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">W/pano-o/pano-ec</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg rl-crit"> 5h ⚠ 89% ~15m </span>
    <span style="width:4px"></span>
    <span class="seg ctx-warn"> ctx 68% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: both limits
capture "claude-statusline-both-limits" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Opus </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">W/pano-o/pano-ec</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg rl-crit"> 5h ⚠ 89% ~15m </span>
    <span style="width:4px"></span>
    <span class="seg rl-warn"> 7d ⚠ 74% ~1.8d </span>
    <span style="width:4px"></span>
    <span class="seg ctx-warn"> ctx 68% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

# Claude: sonnet
capture "claude-statusline-sonnet" '
<div class="terminal">
  <div class="bar claude-bar">
    <span class="seg claude-model"> Sonnet </span>
    <span class="claude-gap"></span>
    <span class="seg claude-path">.dotfiles</span>
    <span class="claude-gap"></span>
    <span class="seg claude-branch">main</span>
    <span class="tmux-spacer"></span>
    <span class="seg ctx-good"> ctx 12% </span>
  </div>
  <div class="claude-ui-bar">
    <span class="claude-ui-mode">⏵⏵ accept edits on</span>
    <span class="claude-ui-spacer"></span>
    <span style="color:#6c7086">medium</span>
  </div>
</div>
'

echo "Done. Gallery HTML: $SCRIPT_DIR/terminal-gallery.html"
