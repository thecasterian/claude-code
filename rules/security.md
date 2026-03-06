# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] Buffer overflow prevention (safe string functions)
- [ ] Integer overflow checks
- [ ] Memory safety (smart pointers, RAII)
- [ ] Format string safety (no user input as format)
- [ ] Path traversal prevention
- [ ] Error messages don't leak sensitive data

See `security-review` skill for detailed patterns, examples, and verification steps.

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
