#!/bin/bash
# Update quiz-progress.html with latest quiz-state.json data
# Then encrypt with staticrypt for deployment

set -e

QUIZ_STATE="/Users/jarvis/clawd/life/areas/projects/general-knowledge/quiz-state.json"
TEMPLATE="/Users/jarvis/clawd/dashboards/src/quiz-progress.html"
OUTPUT_DIR="/Users/jarvis/clawd/dashboards"
PASSWORD="W5l3bA1MFOYkEn0X"

if [ ! -f "$QUIZ_STATE" ]; then
    echo "❌ Error: quiz-state.json not found"
    exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
    echo "❌ Error: template not found at $TEMPLATE"
    exit 1
fi

echo "📊 Updating quiz dashboard..."

# Create temp file with updated data
python3 << 'PYEOF'
import json

template_path = "/Users/jarvis/clawd/dashboards/src/quiz-progress.html"
quiz_state_path = "/Users/jarvis/clawd/life/areas/projects/general-knowledge/quiz-state.json"
output_path = "/tmp/quiz-progress-temp.html"

with open(template_path, 'r') as f:
    html = f.read()

with open(quiz_state_path, 'r') as f:
    quiz_data = json.load(f)

# Replace placeholder with actual data
new_json = json.dumps(quiz_data, ensure_ascii=False)
html = html.replace('QUIZ_DATA_PLACEHOLDER', new_json)

with open(output_path, 'w') as f:
    f.write(html)

print("✅ Template updated with latest quiz data")
PYEOF

# Encrypt with staticrypt
echo "🔐 Encrypting..."
npx staticrypt /tmp/quiz-progress-temp.html -p "$PASSWORD" -d "$OUTPUT_DIR"

echo "✅ Dashboard updated and encrypted!"
echo "📁 Output: $OUTPUT_DIR/quiz-progress-temp.html"

# Rename to final name
mv "$OUTPUT_DIR/quiz-progress-temp.html" "$OUTPUT_DIR/quiz-progress.html"
echo "📁 Final: $OUTPUT_DIR/quiz-progress.html"
