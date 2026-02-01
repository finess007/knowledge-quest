#!/bin/bash
# Sync Nova's brain data to the viewer
# Run this before building to update the data

CLAWD_DIR="/Users/jarvis/clawd"
OUTPUT_FILE="/Users/jarvis/Projects/command-center/src/nova-data.js"

echo "🧠 Syncing Nova's brain data..."

# Start the JS file
echo "const NOVA_DATA = {" > "$OUTPUT_FILE"

# Daily notes (last 14 days)
echo '  dailyNotes: [' >> "$OUTPUT_FILE"
for file in $(ls -t "$CLAWD_DIR/memory/"*.md 2>/dev/null | head -14); do
    name=$(basename "$file")
    date=$(echo "$name" | sed 's/.md$//')
    content=$(cat "$file" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "    {name: \"$name\", date: \"$date\", content: \"$content\"}," >> "$OUTPUT_FILE"
done
echo '  ],' >> "$OUTPUT_FILE"

# MEMORY.md
echo -n '  memory: "' >> "$OUTPUT_FILE"
if [ -f "$CLAWD_DIR/MEMORY.md" ]; then
    cat "$CLAWD_DIR/MEMORY.md" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\n' >> "$OUTPUT_FILE"
fi
echo '",' >> "$OUTPUT_FILE"

# NOW.md
echo -n '  now: "' >> "$OUTPUT_FILE"
if [ -f "$CLAWD_DIR/NOW.md" ]; then
    cat "$CLAWD_DIR/NOW.md" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\n' >> "$OUTPUT_FILE"
fi
echo '",' >> "$OUTPUT_FILE"

# Knowledge graph
echo '  knowledge: {' >> "$OUTPUT_FILE"
for category in people companies projects investments; do
    echo "    $category: [" >> "$OUTPUT_FILE"
    if [ -d "$CLAWD_DIR/life/areas/$category" ]; then
        for entity_dir in "$CLAWD_DIR/life/areas/$category"/*/; do
            if [ -d "$entity_dir" ]; then
                name=$(basename "$entity_dir")
                summary=""
                facts=""
                factCount=0
                
                if [ -f "$entity_dir/summary.md" ]; then
                    summary=$(cat "$entity_dir/summary.md" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
                fi
                
                if [ -f "$entity_dir/items.json" ]; then
                    factCount=$(grep -c '"fact"' "$entity_dir/items.json" 2>/dev/null || echo "0")
                    facts=$(cat "$entity_dir/items.json" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
                fi
                
                echo "      {name: \"$name\", summary: \"$summary\", facts: \"$facts\", factCount: $factCount}," >> "$OUTPUT_FILE"
            fi
        done
    fi
    echo "    ]," >> "$OUTPUT_FILE"
done
echo '  },' >> "$OUTPUT_FILE"

# Cron jobs (simplified - just names and schedules)
echo '  cron: [' >> "$OUTPUT_FILE"
echo '    // Cron data loaded dynamically - see below' >> "$OUTPUT_FILE"
echo '  ]' >> "$OUTPUT_FILE"

echo "};" >> "$OUTPUT_FILE"

echo "✅ Data synced to $OUTPUT_FILE"
echo "📝 Now run ./build.sh to encrypt and deploy"
