Sync all user-level Claude skills and settings from this machine into the repo, then commit and push.

Run these steps:

1. Copy system files into the repo:
```bash
cp ~/.mcp.json .mcp.json
cp ~/.claude/settings.json settings.json
rsync -a --delete --exclude 'gstack' ~/.claude/skills/. skills/
rsync -a --delete ~/.mcpjam/skills/. mcpjam-skills/
```

2. Check if anything changed. If nothing changed, tell the user and stop.

3. If there are changes, show the user a summary of what changed (added/removed/modified files), then commit and push:
```bash
git add -A
git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
git push
```

4. Confirm to the user what was synced and that the push succeeded.
