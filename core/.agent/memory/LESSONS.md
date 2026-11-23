# Lessons learned (append-only, one line each, newest last)
<!-- 
Format: - YYYY-MM-DD [topic] what went wrong → what to do instead
Standard topic tags:
  [auth] [database] [api] [security] [performance] [docker] [ci] [test] [frontend] [data] [architecture]

Query by topic:
  .agent/scripts/kit-context --topic <topic>
  hoặc grep -i "\[topic\]" .agent/memory/LESSONS.md
-->
- 2026-11-20 [auth] Storing JWT in localStorage is vulnerable to XSS → use HttpOnly Secure SameSite Cookie
- 2026-11-21 [ci] sed -i '' fails on Linux GNU sed → use portable sed -i.bak ... && rm -f ...bak
