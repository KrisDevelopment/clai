#!/bin/bash
set -euo pipefail

xdg-open https://browsermcp.io/ 2>/dev/null || true

if [ -n "${OPENCODE_CONFIG:-}" ]; then
  CONFIG="$OPENCODE_CONFIG"
else
  CONFIG=""
  for f in "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.json"; do
    if [ -f "$f" ]; then
      CONFIG="$f"
      break
    fi
  done
  CONFIG="${CONFIG:-$HOME/.config/opencode/opencode.jsonc}"
fi

if [ ! -f "$CONFIG" ]; then
  mkdir -p "$(dirname "$CONFIG")"
  printf '{\n  "$schema": "https://opencode.ai/config.json"\n}\n' > "$CONFIG"
fi

cp "$CONFIG" "$CONFIG.bak.$(date +%s)"

python3 - "$CONFIG" <<'PY'
import json
import sys

path = sys.argv[1]


def strip_comments(text):
    out = []
    i, n = 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\":
                if i + 1 < n:
                    out.append(text[i + 1])
                    i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


with open(path) as f:
    raw = f.read()

data = json.loads(strip_comments(raw))

target = {
    "type": "local",
    "command": ["npx", "@browsermcp/mcp@latest"],
    "enabled": True,
}

mcp = data.setdefault("mcp", {})
if mcp.get("browser") == target:
    print(f"browser MCP already configured in {path}, nothing to do")
    sys.exit(0)

mcp["browser"] = target

with open(path, "w") as f:
    f.write(json.dumps(data, indent=2) + "\n")

print(f"added browser MCP to {path}")
PY
