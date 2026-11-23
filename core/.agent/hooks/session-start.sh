#!/usr/bin/env bash
# SessionStart hook: stdout is injected into the agent's context. Keep it SHORT.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
cat >/dev/null   # consume hook JSON
.agent/scripts/kit-context --brief 2>/dev/null | head -n 70
cat <<'EOF'

### Session rules (agent-kit)
- One task per session. Work only on a task branch (kit-task start TASK-NNN).
- Checkpoint after each green step: .agent/scripts/kit-task checkpoint "<msg>"
- Before ending or when context feels heavy: run the kit-handoff playbook, then start a fresh session.
EOF
exit 0
