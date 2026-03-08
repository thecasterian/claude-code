#!/bin/bash
# PostToolUse hook: auto-format C/C++ files with clang-format
# Only runs when .clang-format exists in the project directory

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path')"
PROJECT_DIR="$(echo "$INPUT" | jq -r '.cwd')"

# Skip if file_path is missing
if [[ -z "$FILE_PATH" || "$FILE_PATH" == "null" ]]; then
    exit 0
fi

# Check if C/C++ file
case "$FILE_PATH" in
    *.c|*.h|*.cpp|*.cc|*.cxx|*.hpp|*.hxx|*.C|*.H)
        ;;
    *)
        exit 0
        ;;
esac

# Walk up from project dir to find .clang-format
dir="$PROJECT_DIR"
found=""
while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.clang-format" ]]; then
        found="$dir/.clang-format"
        break
    fi
    dir="$(dirname "$dir")"
done

if [[ -z "$found" ]]; then
    exit 0
fi

# Check that clang-format is available
if ! command -v clang-format &>/dev/null; then
    echo "clang-format not found in PATH" >&2
    exit 1
fi

# Format the file in place
clang-format -i "$FILE_PATH" 2>&1

exit 0
