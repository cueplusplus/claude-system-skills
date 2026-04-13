Set up this machine with all Claude skills, MCP servers, and settings from this repo.

Run these steps in order:

1. Copy files into place:
```bash
cp .mcp.json ~/.mcp.json
mkdir -p ~/.claude
cp settings.json ~/.claude/settings.json
mkdir -p ~/.claude/skills
cp -r skills/. ~/.claude/skills/
mkdir -p ~/.mcpjam/skills
cp -r mcpjam-skills/. ~/.mcpjam/skills/
```

2. Install gstack (headless browser skill):
```bash
git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
```
If `~/.claude/skills/gstack` already exists, skip this step.

3. Register the piercelamb plugin marketplace:
```bash
claude plugin marketplace add piercelamb-plugins github:piercelamb/deep-implement
```

4. Install all plugins:
```bash
claude plugin install playwright@claude-plugins-official
claude plugin install deep-project@piercelamb-plugins
claude plugin install deep-implement@piercelamb-plugins
claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install linear@claude-plugins-official
claude plugin install vercel@claude-plugins-official
```

5. Tell the user everything is installed and to restart Claude Code.
