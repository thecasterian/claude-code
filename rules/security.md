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

## Secret Management

```cpp
// NEVER: Hardcoded secrets
const char* apiKey = "sk-proj-xxxxx";

// ALWAYS: Environment variables
const char* apiKey = std::getenv("OPENAI_API_KEY");

if (apiKey == nullptr) {
    throw std::runtime_error("OPENAI_API_KEY not configured");
}
```

## Safe String Handling

```cpp
// NEVER: Unsafe functions
strcpy(buffer, user_input);  // Buffer overflow!
printf(user_input);          // Format string vulnerability!

// ALWAYS: Safe alternatives
strncpy(buffer, user_input, sizeof(buffer) - 1);
buffer[sizeof(buffer) - 1] = '\0';
printf("%s", user_input);

// BEST: Use std::string
std::string buffer = user_input;
std::cout << user_input << std::endl;
```

## Memory Safety

```cpp
// NEVER: Raw new/delete
int* data = new int[100];
// ... code that might throw ...
delete[] data;  // May never execute!

// ALWAYS: Smart pointers or containers
auto data = std::make_unique<int[]>(100);
std::vector<int> data(100);
```

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
