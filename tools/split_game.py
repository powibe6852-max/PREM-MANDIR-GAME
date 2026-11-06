#!/usr/bin/env python3
"""Split a single-file game HTML: move every huge inline <script> into web/js/*.js.
Usage: python3 tools/split_game.py game.html web
Keeps script order, so behaviour is identical (index.html becomes small)."""
import os, re, sys
src, out = sys.argv[1], sys.argv[2]
LIMIT = 200_000
s = open(src, encoding="utf-8", newline="").read()
os.makedirs(os.path.join(out, "js"), exist_ok=True)
for f in os.listdir(os.path.join(out, "js")):
    os.remove(os.path.join(out, "js", f))
res, pos, n = [], 0, 0
while True:
    i = s.find("<script", pos)
    if i < 0:
        res.append(s[pos:]); break
    j = s.find(">", i)
    k = s.find("</script>", j)
    head, body = s[i:j + 1], s[j + 1:k]
    if head == "<script>" and len(body) > LIMIT:
        m = re.match(r"\s*window\.([A-Za-z0-9_]+)\s*=", body[:200])
        name = m.group(1) if m else "inline"
        fn = f"{n:02d}_{name}.js"; n += 1
        with open(os.path.join(out, "js", fn), "w", encoding="utf-8", newline="") as fh:
            fh.write(body)
        res.append(s[pos:i] + f'<script charset="utf-8" src="js/{fn}"></script>')
    else:
        res.append(s[pos:k + 9])
    pos = k + 9
with open(os.path.join(out, "index.html"), "w", encoding="utf-8", newline="") as fh:
    fh.write("".join(res))
print(f"split done: {n} js files, index.html = {os.path.getsize(os.path.join(out,'index.html'))} bytes")
