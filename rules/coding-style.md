# Coding Style

## Critical Rules
- **Const correctness** - ALWAYS use const for references, member functions, and variables that don't change
- **RAII / smart pointers** - NEVER use raw new/delete; use `std::make_unique` / `std::make_shared`
- **File organization** - Many small files (200-400 lines, 800 max), organized by feature/domain

See `coding-standards` skill for full patterns and examples.

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No debug print statements
- [ ] No hardcoded values (use macro constants or constexpr)
- [ ] Const correctness maintained
- [ ] Smart pointers used for ownership
