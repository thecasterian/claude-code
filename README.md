## Plugins

- `learning-output-style`
- `clarify`
```bash
# Install
/plugin marketplace add team-attention/plugins-for-claude-natives
/plugin install clarify
```
- `clangd-lsp` — C/C++ language server providing code intelligence, diagnostics, and formatting
```bash
# Install (requires clangd on PATH)
/plugin install clangd-lsp

# Install clangd if not present
# macOS: brew install llvm
# Ubuntu/Debian: sudo apt install clangd
# Fedora: sudo dnf install clang-tools-extra
# Arch Linux: sudo pacman -S clang
```

## MCPs

- Context7
```bash
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp --api-key <YOUR_API_KEY>
```
