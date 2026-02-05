---
name: coding-standards
description: Universal coding standards, best practices, and patterns for C/C++ development.
---

# Coding Standards & Best Practices

Universal coding standards applicable across all C/C++ projects.

## Code Quality Principles

### 1. Readability First
- Code is read more than written
- Clear variable and function names
- Self-documenting code preferred over comments
- Consistent formatting

### 2. KISS (Keep It Simple, Stupid)
- Simplest solution that works
- Avoid over-engineering
- No premature optimization
- Easy to understand > clever code

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into functions
- Create reusable classes/templates
- Share utilities across modules
- Avoid copy-paste programming

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

## C/C++ Standards

### Variable Naming

```cpp
// ✅ GOOD: Descriptive names
const std::string marketSearchQuery = "election";
bool isUserAuthenticated = true;
int totalRevenue = 1000;

// ❌ BAD: Unclear names
const std::string q = "election";
bool flag = true;
int x = 1000;
```

### Function Naming

```cpp
// ✅ GOOD: Verb-noun pattern
MarketData fetchMarketData(const std::string& marketId);
double calculateSimilarity(const std::vector<double>& a, const std::vector<double>& b);
bool isValidEmail(const std::string& email);

// ❌ BAD: Unclear or noun-only
MarketData market(const std::string& id);
double similarity(const std::vector<double>& a, const std::vector<double>& b);
bool email(const std::string& e);
```

### Class Naming

```cpp
// ✅ GOOD: PascalCase for classes
class MarketAnalyzer {
public:
    void analyzeMarket(const Market& market);
private:
    std::vector<Market> markets_;  // member variables with trailing underscore
};

// ❌ BAD: Inconsistent naming
class market_analyzer {
    std::vector<Market> m_markets;  // mixing styles
};
```

### Const Correctness (CRITICAL)

```cpp
// ✅ ALWAYS use const where appropriate
void processData(const std::string& input);  // const reference
int getValue() const;  // const member function
const int MAX_SIZE = 100;  // const for compile-time constants

// ❌ NEVER omit const when it should be used
void processData(std::string input);  // unnecessary copy
int getValue();  // should be const if it doesn't modify state
```

### RAII and Smart Pointers

```cpp
// ✅ ALWAYS use RAII and smart pointers
auto ptr = std::make_unique<MyClass>();
auto sharedPtr = std::make_shared<MyClass>();
std::vector<int> data;  // RAII container

// ❌ NEVER use raw new/delete
MyClass* ptr = new MyClass();  // BAD
delete ptr;  // Easy to forget or double-delete
```

### Error Handling

```cpp
// ✅ GOOD: Comprehensive error handling with exceptions or error codes
std::expected<Data, Error> fetchData(const std::string& url) {
    try {
        auto response = httpClient.get(url);

        if (response.status != 200) {
            return std::unexpected(Error{"HTTP error: " + std::to_string(response.status)});
        }

        return parseResponse(response.body);
    } catch (const std::exception& e) {
        return std::unexpected(Error{std::string("Fetch failed: ") + e.what()});
    }
}

// ❌ BAD: No error handling
Data fetchData(const std::string& url) {
    auto response = httpClient.get(url);
    return parseResponse(response.body);  // Ignores errors
}
```

### Modern C++ Features

```cpp
// ✅ GOOD: Use modern C++ features
auto result = calculateValue();  // auto for complex types
for (const auto& item : items) {  // range-based for
    process(item);
}
auto lambda = [](int x) { return x * 2; };  // lambdas

// ✅ GOOD: Structured bindings (C++17)
auto [key, value] = *map.begin();

// ✅ GOOD: std::optional for nullable values
std::optional<User> findUser(int id);
```

## Memory Management Best Practices

### Use Standard Containers

```cpp
// ✅ GOOD: Standard containers
std::vector<int> numbers;
std::string text;
std::map<std::string, int> counts;
std::array<int, 10> fixedArray;

// ❌ BAD: Raw arrays
int* numbers = new int[100];
char text[256];
```

### Smart Pointer Selection

```cpp
// ✅ Unique ownership - use unique_ptr
std::unique_ptr<Resource> resource = std::make_unique<Resource>();

// ✅ Shared ownership - use shared_ptr
std::shared_ptr<Resource> sharedResource = std::make_shared<Resource>();

// ✅ Non-owning reference - use raw pointer or reference
void process(const Resource& resource);  // reference for guaranteed non-null
void process(Resource* resource);  // pointer when null is valid
```

### Move Semantics

```cpp
// ✅ GOOD: Use move semantics for efficiency
std::vector<int> createLargeVector() {
    std::vector<int> result(1000000);
    // ... populate
    return result;  // Move, not copy (RVO/NRVO)
}

// ✅ GOOD: Perfect forwarding in templates
template<typename T>
void wrapper(T&& arg) {
    doSomething(std::forward<T>(arg));
}
```

## Type Safety

```cpp
// ✅ GOOD: Strong types
enum class Status { Active, Resolved, Closed };

struct Market {
    std::string id;
    std::string name;
    Status status;
    std::chrono::system_clock::time_point createdAt;
};

std::optional<Market> getMarket(const std::string& id);

// ❌ BAD: Weak types
int getMarket(const char* id);  // int for status, raw pointer
```

## Class Design

### Rule of Zero/Five

```cpp
// ✅ GOOD: Rule of Zero - let compiler generate special members
class SimpleClass {
    std::string name_;
    std::vector<int> data_;
    // No need for destructor, copy/move constructors/assignment
};

// ✅ GOOD: Rule of Five - if you define one, define all
class ResourceManager {
public:
    ResourceManager();
    ~ResourceManager();
    ResourceManager(const ResourceManager& other);
    ResourceManager(ResourceManager&& other) noexcept;
    ResourceManager& operator=(const ResourceManager& other);
    ResourceManager& operator=(ResourceManager&& other) noexcept;
private:
    Resource* resource_;  // Only when you MUST manage raw resources
};
```

### Interface Design

```cpp
// ✅ GOOD: Clean interface
class IDataSource {
public:
    virtual ~IDataSource() = default;
    virtual std::vector<Data> fetch() = 0;
    virtual bool isConnected() const = 0;
};

// ✅ GOOD: PIMPL idiom for ABI stability
class Widget {
public:
    Widget();
    ~Widget();
    void doSomething();
private:
    class Impl;
    std::unique_ptr<Impl> pImpl_;
};
```

## File Organization

### Project Structure

```
project/
├── include/              # Public headers
│   └── mylib/
│       ├── api.h
│       └── types.h
├── src/                  # Implementation
│   ├── api.cpp
│   ├── internal.h       # Private headers
│   └── internal.cpp
├── tests/               # Unit tests
│   ├── test_api.cpp
│   └── test_internal.cpp
├── CMakeLists.txt
└── README.md
```

### Header File Structure

```cpp
// myclass.h
#pragma once  // Or traditional include guards

#include <string>
#include <vector>

namespace myproject {

class MyClass {
public:
    explicit MyClass(std::string name);
    ~MyClass() = default;

    const std::string& name() const { return name_; }
    void process();

private:
    std::string name_;
    std::vector<int> data_;
};

}  // namespace myproject
```

### Include Order

```cpp
// 1. Related header (for .cpp files)
#include "myclass.h"

// 2. C system headers
#include <cstdlib>
#include <cstring>

// 3. C++ standard library headers
#include <string>
#include <vector>
#include <memory>

// 4. Other libraries' headers
#include <boost/asio.hpp>
#include <fmt/format.h>

// 5. Project headers
#include "utils.h"
#include "config.h"
```

## Comments & Documentation

### When to Comment

```cpp
// ✅ GOOD: Explain WHY, not WHAT
// Use exponential backoff to avoid overwhelming the API during outages
const int delay = std::min(1000 * static_cast<int>(std::pow(2, retryCount)), 30000);

// Thread-safe: protected by mutex_ (see lock in caller)
void updateCache(const Data& data);

// ❌ BAD: Stating the obvious
// Increment counter by 1
count++;

// Set name to user's name
name = user.name;
```

### Doxygen for Public APIs

```cpp
/**
 * @brief Searches markets using semantic similarity.
 *
 * @param query Natural language search query
 * @param limit Maximum number of results (default: 10)
 * @return Vector of markets sorted by similarity score
 * @throws std::runtime_error If API fails or database unavailable
 *
 * @example
 * @code
 * auto results = searchMarkets("election", 5);
 * std::cout << results[0].name << std::endl; // "Trump vs Biden"
 * @endcode
 */
std::vector<Market> searchMarkets(
    const std::string& query,
    size_t limit = 10
);
```

## Performance Best Practices

### Pass by Reference

```cpp
// ✅ GOOD: Pass large objects by const reference
void process(const std::vector<int>& data);
void process(const std::string& text);

// ✅ GOOD: Pass small types by value
void process(int value);
void process(double value);
void process(std::string_view text);  // C++17 for string views
```

### Reserve Capacity

```cpp
// ✅ GOOD: Reserve capacity to avoid reallocations
std::vector<int> results;
results.reserve(expectedSize);
for (int i = 0; i < expectedSize; ++i) {
    results.push_back(computeValue(i));
}
```

### Avoid Unnecessary Copies

```cpp
// ✅ GOOD: Move when possible
std::vector<Data> getData() {
    std::vector<Data> result;
    // ... populate
    return result;  // RVO applies
}

// ✅ GOOD: Emplace instead of push
std::vector<std::string> strings;
strings.emplace_back("hello");  // Constructs in place

// ❌ BAD: Unnecessary copies
strings.push_back(std::string("hello"));  // Creates temporary
```

## Testing Standards

### Test Structure (AAA Pattern)

```cpp
TEST(SimilarityTest, CalculatesCorrectlyForOrthogonalVectors) {
    // Arrange
    std::vector<double> vector1 = {1.0, 0.0, 0.0};
    std::vector<double> vector2 = {0.0, 1.0, 0.0};

    // Act
    double similarity = calculateCosineSimilarity(vector1, vector2);

    // Assert
    EXPECT_DOUBLE_EQ(similarity, 0.0);
}
```

### Test Naming

```cpp
// ✅ GOOD: Descriptive test names
TEST(MarketSearch, ReturnsEmptyArrayWhenNoMarketsMatchQuery) { }
TEST(ConfigLoader, ThrowsErrorWhenConfigFileMissing) { }
TEST(SearchService, FallsBackToSubstringSearchWhenRedisUnavailable) { }

// ❌ BAD: Vague test names
TEST(MarketSearch, Works) { }
TEST(Search, Test1) { }
```

## Code Smell Detection

### Long Functions
```cpp
// ❌ BAD: Function > 50 lines
void processMarketData() {
    // 100 lines of code
}

// ✅ GOOD: Split into smaller functions
void processMarketData() {
    auto validated = validateData();
    auto transformed = transformData(validated);
    saveData(transformed);
}
```

### Deep Nesting
```cpp
// ❌ BAD: 5+ levels of nesting
if (user) {
    if (user->isAdmin()) {
        if (market) {
            if (market->isActive()) {
                if (hasPermission) {
                    // Do something
                }
            }
        }
    }
}

// ✅ GOOD: Early returns
if (!user) return;
if (!user->isAdmin()) return;
if (!market) return;
if (!market->isActive()) return;
if (!hasPermission) return;

// Do something
```

### Magic Numbers
```cpp
// ❌ BAD: Unexplained numbers
if (retryCount > 3) { }
std::this_thread::sleep_for(std::chrono::milliseconds(500));

// ✅ GOOD: Named constants
constexpr int MAX_RETRIES = 3;
constexpr auto DEBOUNCE_DELAY = std::chrono::milliseconds(500);

if (retryCount > MAX_RETRIES) { }
std::this_thread::sleep_for(DEBOUNCE_DELAY);
```

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
