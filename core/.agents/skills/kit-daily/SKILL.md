---
name: kit-daily
description: Write or update today's daily report in docs/daily (auto data from git + tasks, plus a human-readable summary, blockers, decisions, next steps); weekly roll-up on request. Use at the end of each working session or when asked for a report.
---
# kit-daily

1. `.agent/scripts/kit-daily` → creates/refreshes `docs/daily/<YYYY-MM>/<today>.md` (the AUTO block = commits, tasks, restore points).
2. Fill the human sections in `docs_language` — **outcomes, not activity**:
   - Tóm tắt / Summary (≤ 5 lines) · Đã xong / Done (link TASK ids, PRs) · Đang làm / In progress (% + next step)
   - Vướng mắc / Blockers & risks needing a human decision · Quyết định / Decisions (ADR links) · Kế hoạch / Next
3. Keep previous human text; append rather than rewrite if the report already exists today.
4. Weekly (Friday or on request): `.agent/scripts/kit-daily --week`, then fill its Summary with ≤ 5 outcome bullets,
   tasks done vs planned, top risks for next week.
5. Include the report in the next checkpoint commit.
