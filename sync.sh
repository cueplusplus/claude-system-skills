#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "Syncing from system..."

cp ~/.mcp.json .mcp.json
cp ~/.claude/settings.json settings.json

# Skills — copy all, skip gstack (it's a git repo, tracked separately)
rsync -a --delete \
  --exclude 'gstack' \
  ~/.claude/skills/. skills/

# mcpjam skills
rsync -a --delete \
  ~/.mcpjam/skills/. mcpjam-skills/

echo "Sync complete."

# Commit if there are changes
if git diff --quiet && git diff --cached --quiet; then
  echo "Nothing changed, nothing to commit."
else
  git add -A
  git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
  git push
  echo "Pushed."
fi
