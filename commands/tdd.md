---
description: Enforce test-driven development workflow. Scaffold interfaces, generate tests FIRST, then implement minimal code to pass. Ensure 80%+ coverage.
---

# TDD Command

This command invokes the **tdd-guide** agent to enforce test-driven development methodology.

## What This Command Does

1. **Scaffold Interfaces** - Define types/interfaces first
2. **Generate Tests First** - Write failing tests (RED)
3. **Implement Minimal Code** - Write just enough to pass (GREEN)
4. **Refactor** - Improve code while keeping tests green (REFACTOR)
5. **Verify Coverage** - Ensure 80%+ test coverage

## When to Use

Use `/tdd` when:
- Implementing new features
- Adding new functions/classes
- Fixing bugs (write test that reproduces bug first)
- Refactoring existing code
- Building critical business logic

## How It Works

The tdd-guide agent will:

1. **Define interfaces** for inputs/outputs
2. **Write tests that will FAIL** (because code doesn't exist yet)
3. **Run tests** and verify they fail for the right reason
4. **Write minimal implementation** to make tests pass
5. **Run tests** and verify they pass
6. **Refactor** code while keeping tests green
7. **Check coverage** and add more tests if below 80%

## TDD Cycle

```
RED → GREEN → REFACTOR → REPEAT

RED:      Write a failing test
GREEN:    Write minimal code to pass
REFACTOR: Improve code, keep tests passing
REPEAT:   Next feature/scenario
```

## Example Usage

````markdown
User: /tdd I need a function to calculate market liquidity score

Agent (tdd-guide):
# TDD Session: Market Liquidity Score Calculator

## Step 1: Define Interface (SCAFFOLD)

```cpp
// liquidity.h
#pragma once
#include <chrono>

struct MarketData {
    double totalVolume;
    double bidAskSpread;
    int activeTraders;
    std::chrono::system_clock::time_point lastTradeTime;
};

// Calculate liquidity score (0-100)
double calculateLiquidityScore(const MarketData& market);
```

## Step 2: Write Failing Test (RED)

```cpp
// test_liquidity.cpp
#include <gtest/gtest.h>
#include "liquidity.h"

using namespace std::chrono;

TEST(LiquidityTest, ReturnsHighScoreForLiquidMarket) {
    MarketData market{
        .totalVolume = 100000,
        .bidAskSpread = 0.01,
        .activeTraders = 500,
        .lastTradeTime = system_clock::now()
    };

    double score = calculateLiquidityScore(market);

    EXPECT_GT(score, 80.0);
    EXPECT_LE(score, 100.0);
}

TEST(LiquidityTest, ReturnsLowScoreForIlliquidMarket) {
    MarketData market{
        .totalVolume = 100,
        .bidAskSpread = 0.5,
        .activeTraders = 2,
        .lastTradeTime = system_clock::now() - hours(24)
    };

    double score = calculateLiquidityScore(market);

    EXPECT_LT(score, 30.0);
    EXPECT_GE(score, 0.0);
}

TEST(LiquidityTest, HandlesZeroVolume) {
    MarketData market{
        .totalVolume = 0,
        .bidAskSpread = 0,
        .activeTraders = 0,
        .lastTradeTime = system_clock::now()
    };

    double score = calculateLiquidityScore(market);

    EXPECT_DOUBLE_EQ(score, 0.0);
}
```

## Step 3: Run Tests - Verify FAIL

```bash
cd build && make && ./run_tests

[FAILED] LiquidityTest.ReturnsHighScoreForLiquidMarket
  Undefined reference to calculateLiquidityScore

1 test failed, 0 passed
```

✅ Tests fail as expected. Ready to implement.

## Step 4: Implement Minimal Code (GREEN)

```cpp
// liquidity.cpp
#include "liquidity.h"
#include <algorithm>
#include <cmath>

double calculateLiquidityScore(const MarketData& market) {
    // Handle zero volume edge case
    if (market.totalVolume == 0) {
        return 0.0;
    }

    // Calculate component scores (0-100 scale)
    double volumeScore = std::min(market.totalVolume / 1000.0, 100.0);
    double spreadScore = std::max(100.0 - (market.bidAskSpread * 1000.0), 0.0);
    double traderScore = std::min(static_cast<double>(market.activeTraders) / 10.0, 100.0);

    // Recent activity bonus
    auto now = std::chrono::system_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::hours>(
        now - market.lastTradeTime);
    double hoursSinceLastTrade = duration.count();
    double recencyScore = std::max(100.0 - (hoursSinceLastTrade * 10.0), 0.0);

    // Weighted average
    double score =
        volumeScore * 0.4 +
        spreadScore * 0.3 +
        traderScore * 0.2 +
        recencyScore * 0.1;

    return std::clamp(score, 0.0, 100.0);
}
```

## Step 5: Run Tests - Verify PASS

```bash
cd build && make && ./run_tests

[PASSED] LiquidityTest.ReturnsHighScoreForLiquidMarket
[PASSED] LiquidityTest.ReturnsLowScoreForIlliquidMarket
[PASSED] LiquidityTest.HandlesZeroVolume

3 tests passed
```

✅ All tests passing!

## Step 6: Refactor (IMPROVE)

```cpp
// liquidity.cpp - Refactored with constants and better readability
#include "liquidity.h"
#include <algorithm>
#include <cmath>

namespace {
    constexpr double WEIGHT_VOLUME = 0.4;
    constexpr double WEIGHT_SPREAD = 0.3;
    constexpr double WEIGHT_TRADERS = 0.2;
    constexpr double WEIGHT_RECENCY = 0.1;

    constexpr double SCALE_VOLUME = 1000.0;
    constexpr double SCALE_SPREAD = 1000.0;
    constexpr double SCALE_TRADERS = 10.0;
    constexpr double RECENCY_PENALTY = 10.0;
}

double calculateLiquidityScore(const MarketData& market) {
    if (market.totalVolume == 0) return 0.0;

    double volumeScore = std::min(market.totalVolume / SCALE_VOLUME, 100.0);
    double spreadScore = std::clamp(100.0 - (market.bidAskSpread * SCALE_SPREAD), 0.0, 100.0);
    double traderScore = std::min(static_cast<double>(market.activeTraders) / SCALE_TRADERS, 100.0);

    auto now = std::chrono::system_clock::now();
    auto hours = std::chrono::duration_cast<std::chrono::hours>(
        now - market.lastTradeTime).count();
    double recencyScore = std::clamp(100.0 - (hours * RECENCY_PENALTY), 0.0, 100.0);

    double weightedScore =
        volumeScore * WEIGHT_VOLUME +
        spreadScore * WEIGHT_SPREAD +
        traderScore * WEIGHT_TRADERS +
        recencyScore * WEIGHT_RECENCY;

    return std::clamp(weightedScore, 0.0, 100.0);
}
```

## Step 7: Verify Tests Still Pass

```bash
cd build && make && ./run_tests

[PASSED] LiquidityTest.ReturnsHighScoreForLiquidMarket
[PASSED] LiquidityTest.ReturnsLowScoreForIlliquidMarket
[PASSED] LiquidityTest.HandlesZeroVolume

3 tests passed
```

✅ Refactoring complete, tests still passing!

## Step 8: Check Coverage

```bash
# Build with coverage
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="--coverage" ..
make && ./run_tests

# Generate report
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_report

File           | Lines  | Funcs  | Branches
---------------|--------|--------|----------
liquidity.cpp  | 100%   | 100%   | 100%

Coverage: 100% ✅ (Target: 80%)
```

✅ TDD session complete!
````

## TDD Best Practices

**DO:**
- ✅ Write the test FIRST, before any implementation
- ✅ Run tests and verify they FAIL before implementing
- ✅ Write minimal code to make tests pass
- ✅ Refactor only after tests are green
- ✅ Add edge cases and error scenarios
- ✅ Aim for 80%+ coverage (100% for critical code)

**DON'T:**
- ❌ Write implementation before tests
- ❌ Skip running tests after each change
- ❌ Write too much code at once
- ❌ Ignore failing tests
- ❌ Test implementation details (test behavior)
- ❌ Mock everything (prefer integration tests where possible)

## Test Types to Include

**Unit Tests** (Function-level):
- Happy path scenarios
- Edge cases (empty, null, max values)
- Error conditions
- Boundary values

**Integration Tests** (Component-level):
- API endpoints
- Database operations
- External service calls
- Multi-class interactions

## Coverage Requirements

- **80% minimum** for all code
- **100% required** for:
  - Financial calculations
  - Authentication logic
  - Security-critical code
  - Core business logic

## Important Notes

**MANDATORY**: Tests must be written BEFORE implementation. The TDD cycle is:

1. **RED** - Write failing test
2. **GREEN** - Implement to pass
3. **REFACTOR** - Improve code

Never skip the RED phase. Never write code before tests.

## Integration with Other Commands

- Use `/plan` first to understand what to build
- Use `/tdd` to implement with tests
- Use `/build-fix` if build errors occur
- Use `/code-review` to review implementation
- Use `/test-coverage` to verify coverage

## Related Agents

This command invokes the `tdd-guide` agent located at:
`~/.claude/agents/tdd-guide.md`

And can reference the `tdd-workflow` skill at:
`~/.claude/skills/tdd-workflow/`
