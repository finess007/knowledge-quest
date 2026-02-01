#!/usr/bin/env python3
"""Sync Nova's brain data to the viewer"""

import os
import json
import glob
from pathlib import Path

CLAWD_DIR = "/Users/jarvis/clawd"
OUTPUT_FILE = "/Users/jarvis/Projects/command-center/src/nova-data.js"

def read_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except:
        return ""

def main():
    print("🧠 Syncing Nova's brain data...")
    
    data = {
        "dailyNotes": [],
        "memory": "",
        "now": "",
        "knowledge": {
            "people": [],
            "companies": [],
            "projects": [],
            "investments": []
        },
        "cron": []
    }
    
    # Daily notes (last 14)
    memory_files = sorted(glob.glob(f"{CLAWD_DIR}/memory/*.md"), reverse=True)[:14]
    for f in memory_files:
        name = os.path.basename(f)
        date = name.replace('.md', '')
        content = read_file(f)
        data["dailyNotes"].append({"name": name, "date": date, "content": content})
    print(f"  ✅ {len(data['dailyNotes'])} daily notes")
    
    # MEMORY.md
    data["memory"] = read_file(f"{CLAWD_DIR}/MEMORY.md")
    print(f"  ✅ MEMORY.md ({len(data['memory'])} chars)")
    
    # NOW.md
    data["now"] = read_file(f"{CLAWD_DIR}/NOW.md")
    print(f"  ✅ NOW.md ({len(data['now'])} chars)")
    
    # Knowledge graph
    for category in ["people", "companies", "projects", "investments"]:
        category_dir = f"{CLAWD_DIR}/life/areas/{category}"
        if os.path.isdir(category_dir):
            for entity_dir in glob.glob(f"{category_dir}/*/"):
                name = os.path.basename(entity_dir.rstrip('/'))
                summary = read_file(f"{entity_dir}/summary.md")
                
                facts = ""
                fact_count = 0
                items_file = f"{entity_dir}/items.json"
                if os.path.exists(items_file):
                    try:
                        items = json.loads(read_file(items_file))
                        fact_count = len(items) if isinstance(items, list) else 0
                        facts = json.dumps(items, indent=2)
                    except:
                        pass
                
                data["knowledge"][category].append({
                    "name": name,
                    "summary": summary,
                    "facts": facts,
                    "factCount": fact_count
                })
        print(f"  ✅ {category}: {len(data['knowledge'][category])} entities")
    
    # Write output
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("const NOVA_DATA = ")
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write(";")
    
    print(f"\n✅ Data synced to {OUTPUT_FILE}")
    print("📝 Now run ./build.sh to encrypt and deploy")

if __name__ == "__main__":
    main()
