---
name: security-review
description: Use this skill when handling user input, working with memory, creating network code, or implementing security-sensitive features. Provides comprehensive security checklist and patterns for C/C++.
---

# Security Review Skill

This skill ensures all C/C++ code follows security best practices and identifies potential vulnerabilities.

## When to Activate

- Handling user input
- Working with memory allocation
- Creating network code
- Processing file I/O
- Implementing authentication
- Working with secrets or credentials
- Using system calls
- Processing strings

## Security Checklist

### 1. Secrets Management

#### ❌ NEVER Do This
```cpp
const char* apiKey = "sk-proj-xxxxx";  // Hardcoded secret
const char* dbPassword = "password123"; // In source code
```

#### ✅ ALWAYS Do This
```cpp
const char* apiKey = std::getenv("OPENAI_API_KEY");
const char* dbUrl = std::getenv("DATABASE_URL");

// Verify secrets exist
if (apiKey == nullptr) {
    throw std::runtime_error("OPENAI_API_KEY not configured");
}
```

#### Verification Steps
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] All secrets in environment variables
- [ ] Config files with secrets in .gitignore
- [ ] No secrets in git history

### 2. Buffer Overflow Prevention

#### Always Use Safe Functions
```cpp
// ❌ DANGEROUS - Buffer overflow
char buffer[10];
strcpy(buffer, user_input);  // No bounds checking!
gets(buffer);                 // Never use gets()
sprintf(buffer, "%s", input); // No bounds checking

// ✅ SAFE - Bounds checked
char buffer[10];
strncpy(buffer, user_input, sizeof(buffer) - 1);
buffer[sizeof(buffer) - 1] = '\0';

fgets(buffer, sizeof(buffer), stdin);
snprintf(buffer, sizeof(buffer), "%s", input);

// ✅ BEST - Use std::string
std::string buffer = user_input;
```

#### Verification Steps
- [ ] No use of gets(), strcpy(), sprintf()
- [ ] All array accesses bounds-checked
- [ ] snprintf/strncpy used instead of sprintf/strcpy
- [ ] std::string preferred over char arrays

### 3. Integer Overflow Prevention

#### Check Arithmetic Operations
```cpp
// ❌ DANGEROUS - Integer overflow
size_t size = user_count * sizeof(int);  // Can overflow!
int* array = (int*)malloc(size);

// ✅ SAFE - Check for overflow
if (user_count > SIZE_MAX / sizeof(int)) {
    throw std::overflow_error("Size overflow");
}
size_t size = user_count * sizeof(int);
int* array = (int*)malloc(size);

// ✅ BETTER - Use safe arithmetic (C++20)
#include <numeric>
size_t size;
if (__builtin_mul_overflow(user_count, sizeof(int), &size)) {
    throw std::overflow_error("Size overflow");
}
```

#### Verification Steps
- [ ] Size calculations checked for overflow
- [ ] Signed/unsigned conversions validated
- [ ] Multiplication overflow checked
- [ ] Array index bounds verified

### 4. Memory Safety

#### Use RAII and Smart Pointers
```cpp
// ❌ DANGEROUS - Memory leaks and use-after-free
int* ptr = new int(42);
// ... code that might throw ...
delete ptr;  // May never execute!

// ✅ SAFE - RAII with smart pointers
auto ptr = std::make_unique<int>(42);
// Automatically freed when scope exits

// ❌ DANGEROUS - Double free
int* ptr = new int;
delete ptr;
delete ptr;  // Double free!

// ✅ SAFE - Smart pointer prevents double free
auto ptr = std::make_unique<int>();
// Can't double-delete
```

#### Verification Steps
- [ ] Smart pointers used for heap allocations
- [ ] No manual new/delete pairs
- [ ] No use-after-free patterns
- [ ] No double-free patterns
- [ ] Memory initialized before use

### 5. Command Injection Prevention

#### ❌ NEVER Concatenate User Input in Commands
```cpp
// DANGEROUS - Command injection
char cmd[256];
snprintf(cmd, sizeof(cmd), "ping %s", user_input);
system(cmd);  // User can inject: "; rm -rf /"
```

#### ✅ ALWAYS Validate and Sanitize
```cpp
// SAFE - Validate input format
#include <regex>

bool isValidHostname(const std::string& host) {
    std::regex pattern(R"(^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$)");
    return std::regex_match(host, pattern);
}

// SAFE - Use exec family instead of system()
#include <unistd.h>
if (isValidHostname(user_input)) {
    pid_t pid = fork();
    if (pid == 0) {
        execlp("ping", "ping", "-c", "1", user_input.c_str(), nullptr);
        _exit(1);
    }
}
```

#### Verification Steps
- [ ] No system() with user input
- [ ] Input validated with whitelist patterns
- [ ] exec family used instead of system()
- [ ] Shell metacharacters escaped if needed

### 6. Format String Prevention

#### ❌ NEVER Use User Input as Format String
```cpp
// DANGEROUS - Format string vulnerability
printf(user_input);  // User can read/write memory!
syslog(LOG_INFO, user_input);
```

#### ✅ ALWAYS Use Format Specifier
```cpp
// SAFE - Format specifier used
printf("%s", user_input);
syslog(LOG_INFO, "%s", user_input);

// BETTER - Use iostream
std::cout << user_input << std::endl;
```

#### Verification Steps
- [ ] All printf-family calls use format strings
- [ ] User input never used as format string
- [ ] syslog uses format specifier
- [ ] Consider using iostream instead

### 7. Path Traversal Prevention

#### ✅ Validate and Canonicalize Paths
```cpp
#include <filesystem>
namespace fs = std::filesystem;

std::string safePath(const std::string& baseDir,
                     const std::string& userPath) {
    fs::path base = fs::canonical(baseDir);
    fs::path full = fs::weakly_canonical(base / userPath);

    // Ensure path is under base directory
    auto [baseIt, fullIt] = std::mismatch(
        base.begin(), base.end(), full.begin());

    if (baseIt != base.end()) {
        throw std::runtime_error("Path traversal detected");
    }

    return full.string();
}
```

#### Verification Steps
- [ ] Paths canonicalized before use
- [ ] Path traversal (../) detected and blocked
- [ ] Symbolic links resolved
- [ ] Base directory validated

### 8. Race Condition Prevention

#### ✅ Avoid TOCTOU (Time-of-Check to Time-of-Use)
```cpp
// ❌ DANGEROUS - TOCTOU race condition
if (access(filename, W_OK) == 0) {
    // Another process could change permissions here!
    FILE* f = fopen(filename, "w");
}

// ✅ SAFE - Check and open atomically
FILE* f = fopen(filename, "w");
if (f == nullptr) {
    // Handle error
    return;
}
// File is open with proper permissions
```

#### Verification Steps
- [ ] No separate check-then-use patterns
- [ ] File operations atomic where possible
- [ ] Proper file locking used
- [ ] Shared resources protected by mutex

### 9. Cryptography Best Practices

#### ✅ Use Secure Random Numbers
```cpp
// ❌ DANGEROUS - Predictable random
srand(time(nullptr));
int key = rand();

// ✅ SAFE - Cryptographically secure random
#include <random>

std::vector<uint8_t> secureRandom(size_t length) {
    std::random_device rd;
    std::vector<uint8_t> buffer(length);
    std::generate(buffer.begin(), buffer.end(), std::ref(rd));
    return buffer;
}
```

#### Verification Steps
- [ ] Cryptographic operations use secure libraries
- [ ] Random numbers from std::random_device
- [ ] Deprecated algorithms avoided (MD5, SHA1 for security)
- [ ] Keys not hardcoded

### 10. Network Security

#### ✅ Validate Network Input
```cpp
// ❌ DANGEROUS - Trusting network data
int length;
recv(socket, &length, sizeof(length), 0);
char* buffer = new char[length];  // Attacker controls length!
recv(socket, buffer, length, 0);

// ✅ SAFE - Validate before use
int length;
recv(socket, &length, sizeof(length), 0);
if (length < 0 || length > MAX_MESSAGE_SIZE) {
    throw std::runtime_error("Invalid message length");
}
std::vector<char> buffer(length);
recv(socket, buffer.data(), length, 0);
```

#### Verification Steps
- [ ] Network data validated before use
- [ ] Message sizes bounded
- [ ] TLS/SSL used for sensitive data
- [ ] Connection timeouts set

### 11. Error Handling

#### ✅ Don't Leak Sensitive Information
```cpp
// ❌ DANGEROUS - Exposes internal details
catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    std::cerr << "Stack: " << getStackTrace() << std::endl;
    return -1;
}

// ✅ SAFE - Generic message to user
catch (const std::exception& e) {
    logError(e);  // Internal logging only
    std::cerr << "An error occurred" << std::endl;
    return -1;
}
```

#### Verification Steps
- [ ] Error messages don't expose internals
- [ ] Stack traces not shown to users
- [ ] Detailed errors only in logs
- [ ] All error codes checked

### 12. Compiler Security Flags

#### ✅ Enable Security Features
```cmake
# CMakeLists.txt
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wformat=2 -Wformat-security")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-strong")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FORTIFY_SOURCE=2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIE")

# For Debug - enable sanitizers
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address,undefined")
```

#### Verification Steps
- [ ] Stack protector enabled
- [ ] FORTIFY_SOURCE enabled
- [ ] Position Independent Executables (PIE)
- [ ] Sanitizers used in testing

## Security Testing

### Automated Security Tests
```cpp
// Test buffer overflow protection
TEST(SecurityTest, HandlesOversizedInput) {
    char input[1000];
    memset(input, 'A', sizeof(input) - 1);
    input[sizeof(input) - 1] = '\0';

    EXPECT_NO_THROW(processInput(input));
}

// Test integer overflow protection
TEST(SecurityTest, RejectsOverflowingSize) {
    size_t maliciousSize = SIZE_MAX;
    EXPECT_THROW(allocateBuffer(maliciousSize), std::overflow_error);
}

// Test path traversal protection
TEST(SecurityTest, BlocksPathTraversal) {
    EXPECT_THROW(
        openFile("/safe/dir", "../../../etc/passwd"),
        std::runtime_error
    );
}

// Test command injection protection
TEST(SecurityTest, RejectsInvalidHostname) {
    EXPECT_FALSE(isValidHostname("localhost; rm -rf /"));
    EXPECT_FALSE(isValidHostname("$(cat /etc/passwd)"));
}
```

## Pre-Deployment Security Checklist

Before ANY production deployment:

- [ ] **Secrets**: No hardcoded secrets, all in env vars
- [ ] **Buffer Overflow**: Safe string functions used
- [ ] **Integer Overflow**: Arithmetic checked
- [ ] **Memory Safety**: Smart pointers used
- [ ] **Command Injection**: No system() with user input
- [ ] **Format String**: Format specifiers used
- [ ] **Path Traversal**: Paths validated
- [ ] **Race Conditions**: TOCTOU prevented
- [ ] **Cryptography**: Secure random used
- [ ] **Network**: Input validated
- [ ] **Error Handling**: No sensitive data leaked
- [ ] **Compiler Flags**: Security options enabled
- [ ] **Static Analysis**: cppcheck/clang-tidy clean
- [ ] **Sanitizers**: ASan/UBSan pass

## Resources

- [SEI CERT C Coding Standard](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard)
- [SEI CERT C++ Coding Standard](https://wiki.sei.cmu.edu/confluence/display/cplusplus/SEI+CERT+C%2B%2B+Coding+Standard)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [OWASP](https://owasp.org/)

---

**Remember**: C/C++ gives you power but requires discipline. One vulnerability can compromise an entire system. When in doubt, err on the side of caution.
