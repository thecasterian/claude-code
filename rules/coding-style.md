# Coding Style

## Const Correctness (CRITICAL)

ALWAYS use const where applicable:

```cpp
// WRONG: Missing const
void processData(std::string& data) {
    // only reads data, doesn't modify
}

// CORRECT: Const reference
void processData(const std::string& data) {
    // clearly indicates data won't be modified
}

// CORRECT: Const member function
int getValue() const { return value_; }
```

## RAII and Smart Pointers (CRITICAL)

ALWAYS use RAII, NEVER use raw new/delete:

```cpp
// WRONG: Raw pointers
MyClass* obj = new MyClass();
// ... code that might throw ...
delete obj;  // May never execute!

// CORRECT: Smart pointers
auto obj = std::make_unique<MyClass>();
// Automatically cleaned up
```

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large classes
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:

```cpp
try {
    auto result = riskyOperation();
    return result;
} catch (const std::exception& e) {
    logError("Operation failed: ", e.what());
    throw std::runtime_error("User-friendly error message");
}
```

## Input Validation

ALWAYS validate user input:

```cpp
void processInput(const std::string& input, size_t maxLength) {
    if (input.empty()) {
        throw std::invalid_argument("Input cannot be empty");
    }
    if (input.length() > maxLength) {
        throw std::invalid_argument("Input exceeds maximum length");
    }
    // Process validated input
}
```

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
