import json
import urllib.request
import urllib.error
import sys
import os
from pathlib import Path

# Try to import dotenv, but don't fail if not present (key might be in env vars already)
try:
    from dotenv import load_dotenv
    # Load .env from project root (one directory up from this script)
    env_path = Path(__file__).resolve().parent.parent / '.env'
    load_dotenv(dotenv_path=env_path)
except ImportError:
    pass

# --- CONFIGURATION ---
NOTION_API_KEY = os.getenv("NOTION_API_KEY")

if not NOTION_API_KEY:
    print("Error: NOTION_API_KEY not found in environment variables or .env file.")
    print("Please create a .env file in the project root with NOTION_API_KEY=your_key")
    sys.exit(1)


GRATITUDE_PAGE_ID = "2e3c1eef485d81b29483e350d28ca2ca"

# Page IDs extracted from your provided links
PAGES_TO_RESET = [
    "21fc1eef485d8058a87ff49f37706365", # Startup Routine
    "21fc1eef485d8072b818f2935920bd6e", # Lunchtime Routine
    "21fc1eef485d80fcbe1bc93ce7210342", # Shutdown Routine
]
# ---------------------

HEADERS = {
    "Authorization": f"Bearer {NOTION_API_KEY}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def make_request(url, method="GET", payload=None):
    try:
        data = json.dumps(payload).encode() if payload else None
        req = urllib.request.Request(url, data=data, headers=HEADERS, method=method)
        with urllib.request.urlopen(req) as response:
            if method == "DELETE":
                return None
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        print(f"Request failed: {e.code} {e.reason} for {url}")
        try:
             print(e.read().decode())
        except:
             pass
        return None

def uncheck_blocks(page_id):
    print(f"Checking page: {page_id}...")
    url = f"https://api.notion.com/v1/blocks/{page_id}/children?page_size=100"
    data = make_request(url)

    if not data:
        return

    # Find checked 'to_do' blocks
    blocks_to_update = []
    for block in data.get("results", []):
        if block.get("type") == "to_do":
            if block["to_do"].get("checked"):
                blocks_to_update.append(block["id"])

    # Uncheck them
    if not blocks_to_update:
        print("  - Nothing to uncheck.")
        return

    print(f"  - Unchecking {len(blocks_to_update)} items...")
    for block_id in blocks_to_update:
        update_url = f"https://api.notion.com/v1/blocks/{block_id}"
        payload = {
            "to_do": {
                "checked": False
            }
        }
        make_request(update_url, "PATCH", payload)

def reset_gratitude_page():
    print(f"Resetting Gratitude Page: {GRATITUDE_PAGE_ID}...")
    url = f"https://api.notion.com/v1/blocks/{GRATITUDE_PAGE_ID}/children?page_size=100"
    data = make_request(url)
    
    if not data or "results" not in data:
        print("  - Failed to fetch gratitude page blocks.")
        return

    blocks = data["results"]
    
    def get_text(block):
        btype = block.get("type")
        if not btype or btype not in block: return ""
        rich_text = block[btype].get("rich_text", [])
        return "".join([t.get("plain_text", "") for t in rich_text])

    i = 0
    while i < len(blocks):
        block = blocks[i]
        text = get_text(block)
        
        # Check for headers
        if "Part 1" in text or "Part 2" in text:
            print(f"  - Found section: {text.strip()}")
            
            # Inspect subsequent blocks
            next_idx = i + 1
            if next_idx < len(blocks):
                first_child = blocks[next_idx]
                
                # Check if it's a bullet list item
                if first_child["type"] == "bulleted_list_item":
                    # Check if it is already empty
                    current_text = get_text(first_child)
                    if current_text.strip() != "":
                        print(f"    - Clearing text in first bullet: {first_child['id']}")
                        update_url = f"https://api.notion.com/v1/blocks/{first_child['id']}"
                        payload = { "bulleted_list_item": { "rich_text": [] } }
                        make_request(update_url, "PATCH", payload)
                    else:
                        print(f"    - First bullet is already empty.")
                    
                    # Delete any SUBSEQUENT bullets
                    j = next_idx + 1
                    while j < len(blocks):
                        candidate = blocks[j]
                        if candidate["type"] == "bulleted_list_item":
                            print(f"    - Deleting extra bullet: {candidate['id']}")
                            del_url = f"https://api.notion.com/v1/blocks/{candidate['id']}"
                            make_request(del_url, "DELETE")
                            j += 1
                        else:
                            break
                    
                    # Advance i to skip the processed blocks
                    i = j - 1 
                else:
                    print(f"    - Warning: Block following header is not a bullet list item ({first_child['type']}). Skipping.")
            else:
                print("    - Warning: Header is the last block.")
        
        i += 1

if __name__ == "__main__":
    for page_id in PAGES_TO_RESET:
        uncheck_blocks(page_id)
        
    reset_gratitude_page()
