#!/usr/bin/env bash
# e2e of the kit workflow: kit init (node + ba + openspec) → BA scaffolds → OpenSpec change → task → gates → finish (archive change)
# → merge → done task archived. Needs network (npm, npx OpenSpec). Usage: E2E_WORK=/tmp/x tests/e2e-workflow.sh
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)/kit"
SP="${E2E_WORK:-$(mktemp -d)}"
P="$SP/e2e-$(date +%s)"; mkdir -p "$P/src"; cd "$P"
export GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

printf '{"name":"e2e","version":"1.0.0","type":"module","scripts":{"test":"echo ok"}}\n' > package.json
printf '{"compilerOptions":{"strict":true,"module":"nodenext","target":"es2022","noEmit":true},"include":["src"]}\n' > tsconfig.json
printf 'export const add = (a: number, b: number): number => a + b;\n' > src/index.ts
step "kit init"
"$KIT" init . --stack node --modules ba,openspec --yes --deps --no-tools --lang vi 2>&1 | grep -E 'installed|ERROR' || true
npx --no-install prettier --write package.json tsconfig.json >/dev/null
git add -A && git commit -qm "chore: initial commit with agent-kit" && git branch develop && git checkout -q develop

step "planning on develop (uncommitted): use case, story, change"
N=.agent/scripts/kit-new
$N usecase "Chào người dùng"; $N story "Hiển thị lời chào theo tên" --uc UC-01; $N change add-greeting "Greeting by name" | head -1
C=openspec/changes/add-greeting; mkdir -p $C/specs/greeting
cat > $C/proposal.md <<'MD'
# Proposal

## Source
- Goal: G1
- Use cases / stories: UC-01, US-01

## Clarifications
| # | Question | Answer | Who / date |
|---|---|---|---|
| 1 | Empty name? | "Xin chào, bạn" | PO |

## Why
Personalised greeting.

## What Changes
- Add `greet(name)`.

## Capabilities

### New Capabilities
- `greeting`: greeting by user name

### Modified Capabilities

## Impact
`src/greeting.ts`

## Out of scope
- i18n

## Kit tasks
- TASK-001
MD
cat > $C/specs/greeting/spec.md <<'MD'
# Spec Delta

## Purpose

Create a personalised greeting from the user's name for display in the user interface.

## ADDED Requirements

### Requirement: Greeting by name
The system SHALL return a greeting containing the trimmed user name.

#### Scenario: US-01 AC1 — named user is greeted
- **WHEN** greet is called with "An"
- **THEN** it returns "Xin chào, An"

#### Scenario: US-01 AC2 — empty name falls back
- **WHEN** greet is called with an empty or blank name
- **THEN** it returns "Xin chào, bạn"
MD
cat > $C/design.md <<'MD'
# Design

## Context
Pure function.

## Impact & reuse
None found.

## Decisions
Pure function in `src/greeting.ts`.

## Test plan
| Scenario | Level | Test | Data |
|---|---|---|---|
| US-01 AC1 | unit | src/greeting.test.ts | "An" |

## Rules applied
.agent/rules/stack/node.md
MD
printf '# Tasks\n\n## 1. Greeting function (TASK-001)\n\n- [ ] 1.1 Write failing tests and verify they fail\n- [ ] 1.2 Implement greet and verify tests pass\n' > $C/tasks.md
.agent/scripts/kit-openspec validate add-greeting --strict --no-interactive

step "task linked to change; start carries planning docs"
T=.agent/scripts/kit-task
$T new "Hàm chào theo tên" --change add-greeting --priority P1 >/dev/null
$T start TASK-001 | tail -1
F=$(ls .agent/tasks/TASK-001-*.md)
step "verify must FAIL on an empty task"
if $T verify >/dev/null 2>&1; then echo "UNEXPECTED: verify passed"; exit 1; else echo "ok: blocked"; fi

step "do the work"
python3 - "$F" <<'EOF'
import sys;p=sys.argv[1];s=open(p).read()
s=s.replace("## 2. Clarifications","Cần hàm chào theo tên (UC-01, US-01).\n\n## 2. Clarifications",1)
s=s.replace("|---|---|---|---|\n","|---|---|---|---|\n| 1 | Tên rỗng? | \"Xin chào, bạn\" | PO |\n",1)
s=s.replace("- [ ] AC1 — Given … When … Then …","- [ ] AC1 — Given \"An\" When greet Then \"Xin chào, An\"\n- [ ] AC2 — Given rỗng When greet Then \"Xin chào, bạn\"")
s=s.replace("## 4. Test plan","Hàm thuần src/greeting.ts.\n\n## 4. Test plan",1)
open(p,'w').write(s)
EOF
step "verify must FAIL while the clarification checklist is not walked"
if $T verify >/dev/null 2>&1; then echo "UNEXPECTED: verify passed with an unticked checklist"; exit 1; else echo "ok: blocked (checklist)"; fi
python3 - "$F" <<'EOF'
import re,sys;p=sys.argv[1];s=open(p).read()
s=re.sub(r"^- \[ \] (Actor|Data|Edge|Errors|Numbers|State|Integrations|Scope)", r"- [x] \1", s, flags=re.M)
s=s.replace("| 1 | Tên rỗng? | \"Xin chào, bạn\" | PO |","| 1 | Tên rỗng? | \"Xin chào, bạn\" | PO |\n\nASSUMPTION: tên tối đa 50 ký tự",1)
open(p,'w').write(s)
EOF
step "verify must FAIL while an ASSUMPTION is unconfirmed"
vrc=0; vout="$($T verify 2>&1)" || vrc=$?
if [ "$vrc" -ne 0 ] && printf '%s\n' "$vout" | grep -q 'unconfirmed assumptions'; then echo "ok: blocked (assumption)"; else echo "UNEXPECTED: open ASSUMPTION not reported"; exit 1; fi
sed -i.bak 's/^ASSUMPTION: tên tối đa 50 ký tự/CONFIRMED: tên tối đa 50 ký tự (PO, e2e)/' "$F" && rm -f "$F.bak"
$N testplan TASK-001 >/dev/null
printf "import { greet } from './greeting.js';\n\nexport const cases: [string, string][] = [\n  ['An', greet('An')],\n  ['', greet('')],\n];\n" > src/greeting.test.ts
printf "export const greet = (name: string): string => {\n  const n = name.trim();\n  return n === '' ? 'Xin chào, bạn' : \`Xin chào, \${n}\`;\n};\n" > src/greeting.ts
npx --no-install prettier --write src >/dev/null
sed -i.bak 's/^- \[ \] AC/- [x] AC/' "$F" && rm -f "$F.bak"
sed -i.bak 's/^- \[ \]/- [x]/' "$C/tasks.md" && rm -f "$C/tasks.md.bak"
python3 - "$F" <<'EOF'
import sys;p=sys.argv[1];s=open(p).read()
s=s.replace("## Risks / rollback notes","Thêm greet() + test; spec greeting archive vào openspec/specs.\n\n## Risks / rollback notes",1)
open(p,'w').write(s)
EOF
step "verify must FAIL while the test plan does not point to real tests"
if $T verify >/dev/null 2>&1; then echo "UNEXPECTED: verify passed with empty 'Automated in'"; exit 1; else echo "ok: blocked (unresolved test refs)"; fi
python3 - docs/qa/TASK-001.md <<'PY'
import sys;p=sys.argv[1];s=open(p).read()
s=s.replace("| TC-01 | AC1","| TC-01 | AC1",1)
lines=[]
for l in s.split("\n"):
    if l.startswith("| TC-01 "): l=l.replace("| | todo |","| src/greeting.test.ts::'An' | automated |")
    if l.startswith("| TC-02 "): l=l.replace("| | todo |","| src/greeting.test.ts::greet('') | automated |")
    lines.append(l)
open(p,"w").write("\n".join(lines))
PY
grep -E '^\| TC-0' docs/qa/TASK-001.md | cut -c1-40
step "verify must FAIL without a recorded code review, and while a MAJOR is open"
vrc=0; vout="$($T verify 2>&1)" || vrc=$?
if [ "$vrc" -ne 0 ] && printf '%s\n' "$vout" | grep -q 'no code review recorded'; then echo "ok: blocked (no review)"; else echo "UNEXPECTED: missing review not reported"; exit 1; fi
$T checkpoint "greet implemented" | tail -1   # the review covers committed code only
$T review "BLOCKER 0 · MAJOR 1 open · MINOR 0 — by e2e" | tail -1
vrc=0; vout="$($T verify 2>&1)" || vrc=$?
if [ "$vrc" -ne 0 ] && printf '%s\n' "$vout" | grep -q 'open BLOCKER/MAJOR'; then echo "ok: blocked (open MAJOR)"; else echo "UNEXPECTED: open MAJOR not reported"; exit 1; fi
$T review "BLOCKER 0 · MAJOR 1 fixed · MINOR 0 — by e2e" | tail -1
$T checkpoint "review recorded" | tail -1

step "finish: gates + check + archive change"
$T finish 2>&1 | grep -E '✓|✗|archiv|ERROR|no remote|OK' | grep -v 'change/add-greeting' || true
step "result"
[ -f openspec/specs/greeting/spec.md ] || { echo "FAIL: change was not archived into specs"; exit 1; }
find openspec/specs -name spec.md; ls openspec/changes/archive/
git log --format='%s' -4

step "merge, next start archives the done task"
git checkout -q develop && git merge -q --no-ff --no-verify feature/TASK-001-ham-chao-theo-ten -m "Merge TASK-001" && echo merged
$T new "Next task" >/dev/null
$T start TASK-002 | grep -E 'done|archive|on '
find .agent/tasks -name 'TASK-*.md' | sort
$T list
ls .agent/tasks/archive/*/TASK-001-*.md >/dev/null || { echo "FAIL: TASK-001 not archived"; exit 1; }
echo; echo "E2E OK: $P"
