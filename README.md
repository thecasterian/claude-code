## Getting Started

1. Copy files to `~/.claude`
```bash
cp -r agents ~/.claude
cp -r commands ~/.claude
cp -r hooks ~/.claude
cp -r rules ~/.claude
cp -r skills ~/.claude
cp CLAUDE.md ~/.claude
cp settings.json ~/.claude
```
2. Install `learning-output-style` plugin
3. Install Context7 MCP
```bash
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp --api-key <YOUR_API_KEY>
```
