#!/bin/bash
# Reference: https://torch.vision/posts/claude-english-lecturer-hook

INPUT_PROMPT="$(cat | jq '.prompt')"
ORIGINAL_PROMPT="$INPUT_PROMPT"

if [[ -n "$REWRITER_LOCK" ]]; then
    exit 0
fi

TARGET_LANGUAGE="Korean"
JSON_SCHEMA='
{
    "type": "object",
    "properties": {
        "enhanced_prompt": {
            "type": "string",
            "description": "The improved prompt preserving original meaning"
        },
        "has_corrections": {
            "type": "boolean",
            "description": "Whether the original prompt had any issues to improve"
        },
        "praise": {
            "type": "string",
            "description": "One encouraging praise sentence in Korean about what the user did well"
        },
        "corrections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "original": { "type": "string" },
                    "suggestion": { "type": "string" },
                    "category": {
                        "type": "string",
                        "enum": ["grammar", "vocabulary", "style", "spelling", "word_order"]
                    },
                    "explanation": { "type": "string" }
                },
                "required": ["original", "suggestion", "category", "explanation"]
            },
            "description": "Gentle improvement suggestions, max 3 items"
        },
        "tip": {
            "type": "string",
            "description": "One concise learning tip in Korean"
        },
        "is_korean_only": {
            "type": "boolean",
            "description": "True if the original prompt is entirely in Korean with no English"
        },
        "english_translation": {
            "type": "string",
            "description": "Natural English translation of the Korean prompt. Only provided when is_korean_only is true."
        }
    },
    "required": ["enhanced_prompt", "has_corrections", "praise", "corrections", "tip", "is_korean_only", "english_translation"]
}
'

INPUT_PROMPT="\
You are a supportive, encouraging English coach for a Korean developer. Analyze the prompt below and return structured JSON.

Rules:
1. enhanced_prompt: Rewrite to be clear, natural, professional English. Preserve the original intent exactly. If the prompt is code-only or already perfect English, return it unchanged.
2. has_corrections: true if you made any meaningful improvements, false if the prompt was already correct or is pure code/commands.
3. praise: Always write one specific, genuine praise sentence in $TARGET_LANGUAGE about what the user did well (e.g., good vocabulary choice, clear sentence structure, natural phrasing). Even if there are corrections, find something positive first. If the prompt is already perfect, praise their fluency.
4. corrections: List up to 3 gentle improvement suggestions. Each must have:
   - original: the phrase from the original prompt
   - suggestion: the improved phrase
   - category: one of grammar, vocabulary, style, spelling, word_order
   - explanation: brief explanation in $TARGET_LANGUAGE (1 sentence, max 20 words). Frame as \"이렇게 하면 더 자연스러워요\" not \"이건 틀렸어요\".
5. tip: One memorable tip in $TARGET_LANGUAGE (1 sentence, max 30 words) about the most useful pattern. If no corrections, share a useful English expression tip.
6. is_korean_only: true if the entire prompt is written in Korean (no English words except technical terms like API, git, etc.).
7. english_translation: If is_korean_only is true, provide a natural, professional English translation of the Korean prompt. This helps the user learn how to express the same idea in English. If is_korean_only is false, return an empty string.

Focus on patterns Korean speakers commonly struggle with: articles (a/the), prepositions, singular/plural, tense consistency, word order.

<PROMPT>
$INPUT_PROMPT
</PROMPT>\
"

RESPONSE="$( \
    REWRITER_LOCK=1 claude \
    --model sonnet \
    --output-format json \
    --json-schema "$JSON_SCHEMA" \
    -p "$INPUT_PROMPT"
)"

STRUCTURED_OUTPUT="$(echo "$RESPONSE" | jq -r '.structured_output')"

if [[ -z "$STRUCTURED_OUTPUT" || "$STRUCTURED_OUTPUT" == "null" ]]; then
    OUTPUT_PROMPT="Failed to generate lesson."
else
    ENHANCED="$(echo "$STRUCTURED_OUTPUT" | jq -r '.enhanced_prompt')"
    HAS_CORRECTIONS="$(echo "$STRUCTURED_OUTPUT" | jq -r '.has_corrections')"
    PRAISE="$(echo "$STRUCTURED_OUTPUT" | jq -r '.praise')"
    TIP="$(echo "$STRUCTURED_OUTPUT" | jq -r '.tip')"
    IS_KOREAN_ONLY="$(echo "$STRUCTURED_OUTPUT" | jq -r '.is_korean_only')"
    ENGLISH_TRANSLATION="$(echo "$STRUCTURED_OUTPUT" | jq -r '.english_translation')"

    if [[ "$IS_KOREAN_ONLY" == "true" && -n "$ENGLISH_TRANSLATION" && "$ENGLISH_TRANSLATION" != "null" ]]; then
        # Korean-only input: show translation + any learning tips
        if [[ "$HAS_CORRECTIONS" == "true" ]]; then
            CORRECTIONS_DISPLAY="$(echo "$STRUCTURED_OUTPUT" | jq -r '
                .corrections[] |
                "- **\(.category)**: \(.original) → **\(.suggestion)**\n  - \(.explanation)"
            ')"
            OUTPUT_PROMPT="🤖 \"$PRAISE\"

🧙 \"$ORIGINAL_PROMPT\"
-> **$ENGLISH_TRANSLATION**

✨ **더 자연스러운 표현:**
$CORRECTIONS_DISPLAY

💡 $TIP"
        else
            OUTPUT_PROMPT="🤖 \"$PRAISE\"

🧙 \"$ORIGINAL_PROMPT\"
-> **$ENGLISH_TRANSLATION**

💡 $TIP"
        fi
    elif [[ "$HAS_CORRECTIONS" == "true" ]]; then
        CORRECTIONS_DISPLAY="$(echo "$STRUCTURED_OUTPUT" | jq -r '
            .corrections[] |
            "- **\(.category)**: \(.original) → **\(.suggestion)**\n  - \(.explanation)"
        ')"
        OUTPUT_PROMPT="🤖 \"$PRAISE\"

🧙 \"$ORIGINAL_PROMPT\"
-> **$ENHANCED**

✨ **더 자연스러운 표현:**
$CORRECTIONS_DISPLAY

💡 $TIP"
    else
        OUTPUT_PROMPT="👍 \"$PRAISE\"

💡 $TIP"
    fi
fi

# Instruct Claude to display the lesson in a visual format
cat <<EOF
This is an English lesson for the user. Display this lesson to the user at the END of your response using this EXACT visual format:

\`★ English Lesson ────────────────────────────────\`
$OUTPUT_PROMPT
\`─────────────────────────────────────────────────\`

Do NOT skip or dismiss this lesson. Always display it.
EOF

exit 0
