# claude-system-skills

Portable Claude Code user-level setup: MCP servers, skills, and settings.

When given this repo, Claude can run the full setup automatically on a new machine.

---

## What's included

```
skills/           → ~/.claude/skills/   (user-level Claude skills)
mcpjam-skills/    → ~/.mcpjam/skills/   (mcpjam skills)
.mcp.json         → ~/.mcp.json         (MCP server definitions)
settings.json     → ~/.claude/settings.json (enabled plugins, preferences)
```

---

## Setup instructions for Claude

If you are Claude and have been given this repo to set up a new machine, follow these steps exactly:

### Step 1 — Clone the repo

```bash
git clone https://github.com/cueplusplus/claude-system-skills.git /tmp/claude-system-skills
cd /tmp/claude-system-skills
```

### Step 2 — Copy files into place

```bash
# MCP servers
cp .mcp.json ~/.mcp.json

# Claude settings (creates ~/.claude if needed)
mkdir -p ~/.claude
cp settings.json ~/.claude/settings.json

# User-level skills
mkdir -p ~/.claude/skills
cp -r skills/. ~/.claude/skills/

# mcpjam skills
mkdir -p ~/.mcpjam/skills
cp -r mcpjam-skills/. ~/.mcpjam/skills/
```

### Step 3 — Register plugin marketplaces

```bash
claude plugin marketplace add piercelamb-plugins github:piercelamb/deep-implement
```

### Step 4 — Install plugins

```bash
claude plugin install playwright@claude-plugins-official
claude plugin install deep-project@piercelamb-plugins
claude plugin install deep-implement@piercelamb-plugins
claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install linear@claude-plugins-official
claude plugin install vercel@claude-plugins-official
```

> Note: `deep-plan@piercelamb-plugins` is installed but disabled by default (this is intentional).

### Step 5 — Install gstack (headless browser skill)

`gstack` is a standalone skill with its own repo and must be cloned separately:

```bash
git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
```

### Step 6 — Clean up

```bash
rm -rf /tmp/claude-system-skills
```

### Done

Restart Claude Code. All MCP servers, skills, and plugin settings will be active.

---

## Keeping this repo up to date

To sync changes from the current machine back to this repo, run from the repo root:

```bash
cp ~/.mcp.json .mcp.json
cp ~/.claude/settings.json settings.json
cp -r ~/.claude/skills/. skills/
cp -r ~/.mcpjam/skills/. mcpjam-skills/
git add -A && git commit -m "sync" && git push
```
