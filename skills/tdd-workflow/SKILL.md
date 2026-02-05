---
name: tdd-workflow
description: Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit and integration tests.
---

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Activate

- Writing new features or functionality
- Fixing bugs or issues
- Refactoring existing code
- Adding new APIs or interfaces
- Creating new classes or modules

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests
- Individual functions and methods
- Class logic
- Pure functions
- Helpers and utilities

#### Integration Tests
- API endpoints
- Database operations
- Service interactions
- External library calls

## TDD Workflow Steps

### Step 1: Write User Stories
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Generate Test Cases
For each user story, create comprehensive test cases:

```cpp
#include <gtest/gtest.h>
#include "market_search.h"

class SemanticSearchTest : public ::testing::Test {
protected:
    MarketSearch searcher;
};

TEST_F(SemanticSearchTest, ReturnsRelevantMarketsForQuery) {
    auto results = searcher.search("election");

    EXPECT_GT(results.size(), 0);
    EXPECT_TRUE(containsRelevantMarket(results, "election"));
}

TEST_F(SemanticSearchTest, HandlesEmptyQueryGracefully) {
    auto results = searcher.search("");

    EXPECT_TRUE(results.empty());
}

TEST_F(SemanticSearchTest, FallsBackToSubstringSearchWhenRedisUnavailable) {
    // Simulate Redis failure
    searcher.setRedisAvailable(false);

    auto results = searcher.search("trump");

    EXPECT_FALSE(results.empty());
    EXPECT_TRUE(results[0].usedFallback);
}

TEST_F(SemanticSearchTest, SortsResultsBySimilarityScore) {
    auto results = searcher.search("election");

    for (size_t i = 1; i < results.size(); ++i) {
        EXPECT_GE(results[i-1].score, results[i].score);
    }
}
```

### Step 3: Run Tests (They Should Fail)
```bash
cd build && make && ./run_tests
# Tests should fail - we haven't implemented yet
```

### Step 4: Implement Code
Write minimal code to make tests pass:

```cpp
// Implementation guided by tests
std::vector<SearchResult> MarketSearch::search(const std::string& query) {
    if (query.empty()) {
        return {};
    }

    if (isRedisAvailable()) {
        return semanticSearch(query);
    }

    return substringSearch(query);
}
```

### Step 5: Run Tests Again
```bash
cd build && make && ./run_tests
# Tests should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

### Step 7: Verify Coverage
```bash
# Build with coverage flags
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="--coverage" ..
make && ./run_tests

# Generate coverage report
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_report
# Verify 80%+ coverage achieved
```

## Testing Patterns

### Unit Test Pattern (GoogleTest)
```cpp
#include <gtest/gtest.h>
#include "button.h"

class ButtonTest : public ::testing::Test {
protected:
    void SetUp() override {
        button = std::make_unique<Button>("Click me");
    }

    std::unique_ptr<Button> button;
};

TEST_F(ButtonTest, RendersWithCorrectText) {
    EXPECT_EQ(button->getText(), "Click me");
}

TEST_F(ButtonTest, CallsOnClickWhenClicked) {
    bool clicked = false;
    button->setOnClick([&clicked]() { clicked = true; });

    button->click();

    EXPECT_TRUE(clicked);
}

TEST_F(ButtonTest, IsDisabledWhenDisabledFlagSet) {
    button->setDisabled(true);

    EXPECT_TRUE(button->isDisabled());
    EXPECT_FALSE(button->canClick());
}
```

### API Integration Test Pattern
```cpp
#include <gtest/gtest.h>
#include "http_server.h"
#include "http_client.h"

class MarketAPITest : public ::testing::Test {
protected:
    void SetUp() override {
        server = std::make_unique<TestServer>(8080);
        server->start();
        client = std::make_unique<HttpClient>("http://localhost:8080");
    }

    void TearDown() override {
        server->stop();
    }

    std::unique_ptr<TestServer> server;
    std::unique_ptr<HttpClient> client;
};

TEST_F(MarketAPITest, ReturnsMarketsSuccessfully) {
    auto response = client->get("/api/markets");

    EXPECT_EQ(response.status, 200);
    EXPECT_TRUE(response.json["success"].asBool());
    EXPECT_TRUE(response.json["data"].isArray());
}

TEST_F(MarketAPITest, ValidatesQueryParameters) {
    auto response = client->get("/api/markets?limit=invalid");

    EXPECT_EQ(response.status, 400);
}

TEST_F(MarketAPITest, HandlesDatabaseErrorsGracefully) {
    server->setDatabaseAvailable(false);

    auto response = client->get("/api/markets");

    EXPECT_EQ(response.status, 503);
}
```

## Test File Organization

```
project/
├── src/
│   ├── market_search.cpp
│   ├── market_search.h
│   └── button/
│       ├── button.cpp
│       └── button.h
├── tests/
│   ├── unit/
│   │   ├── test_market_search.cpp
│   │   └── test_button.cpp
│   ├── integration/
│   │   ├── test_market_api.cpp
│   │   └── test_database.cpp
│   └── CMakeLists.txt
└── CMakeLists.txt
```

## Mocking External Services

### Mock Database with GMock
```cpp
#include <gmock/gmock.h>
#include "database_interface.h"

class MockDatabase : public IDatabase {
public:
    MOCK_METHOD(std::vector<Market>, getMarkets, (), (override));
    MOCK_METHOD(std::optional<Market>, getMarketById, (int id), (override));
    MOCK_METHOD(bool, insertMarket, (const Market& market), (override));
};

TEST(MarketServiceTest, ReturnsMarketsFromDatabase) {
    MockDatabase mockDb;
    MarketService service(&mockDb);

    std::vector<Market> expectedMarkets = {
        {"1", "Test Market 1"},
        {"2", "Test Market 2"}
    };

    EXPECT_CALL(mockDb, getMarkets())
        .WillOnce(::testing::Return(expectedMarkets));

    auto results = service.getAllMarkets();

    EXPECT_EQ(results.size(), 2);
    EXPECT_EQ(results[0].id, "1");
}
```

### Mock HTTP Client
```cpp
class MockHttpClient : public IHttpClient {
public:
    MOCK_METHOD(HttpResponse, get, (const std::string& url), (override));
    MOCK_METHOD(HttpResponse, post, (const std::string& url, const std::string& body), (override));
};

TEST(ExternalAPITest, HandlesTimeoutGracefully) {
    MockHttpClient mockClient;
    ExternalService service(&mockClient);

    EXPECT_CALL(mockClient, get(::testing::_))
        .WillOnce(::testing::Throw(std::runtime_error("Timeout")));

    EXPECT_THROW(service.fetchData(), std::runtime_error);
}
```

## Test Coverage Verification

### Run Coverage Report
```bash
# Build with coverage
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="--coverage -fprofile-arcs -ftest-coverage" ..
make

# Run tests
./run_tests

# Generate report
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/test/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage_report
```

### Coverage Thresholds (CMake)
```cmake
# In CMakeLists.txt
option(ENABLE_COVERAGE "Enable coverage reporting" OFF)

if(ENABLE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()
```

## Common Testing Mistakes to Avoid

### Don't Test Implementation Details
```cpp
// ❌ WRONG: Testing internal state
EXPECT_EQ(component.internalCounter_, 5);
```

### Test Observable Behavior
```cpp
// ✅ CORRECT: Test what users see
EXPECT_EQ(component.getDisplayValue(), "Count: 5");
```

### Don't Make Tests Depend on Each Other
```cpp
// ❌ WRONG: Tests depend on each other
TEST(UserTest, CreatesUser) { /* ... */ }
TEST(UserTest, UpdatesSameUser) { /* depends on previous test */ }
```

### Use Independent Tests
```cpp
// ✅ CORRECT: Each test sets up its own data
TEST(UserTest, CreatesUser) {
    auto user = createTestUser();
    // Test logic
}

TEST(UserTest, UpdatesUser) {
    auto user = createTestUser();
    // Update logic
}
```

## Continuous Testing

### Watch Mode During Development
```bash
# Using entr for file watching
find src tests -name "*.cpp" -o -name "*.h" | \
    entr -c sh -c "cd build && make && ./run_tests"
```

### Pre-Commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit
cd build && make && ./run_tests
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

### CI/CD Integration (GitHub Actions)
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure CMake
        run: cmake -B build -DENABLE_COVERAGE=ON

      - name: Build
        run: cmake --build build --parallel

      - name: Run Tests
        run: cd build && ctest --output-on-failure

      - name: Generate Coverage
        run: |
          lcov --capture --directory build --output-file coverage.info
          lcov --remove coverage.info '/usr/*' --output-file coverage.info

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage.info
```

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - Null, empty, large values
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- Tests catch bugs before production

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
