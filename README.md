# agent-kit — bộ khung harness cho AI coding agent (mọi ngôn ngữ)

Kit chứa **đủ mọi stack và module**. Lệnh `kit init` hỏi bạn chọn gì, rồi **chỉ cài phần đã chọn** vào dự án (mới hoặc đang có):
convention chuẩn cộng đồng của từng ngôn ngữ (kèm file config tool thật), rules, playbook, hook, CI, BA, SA, Docker.

```bash
git clone <repo-agent-kit> ~/agent-kit
~/agent-kit/kit init /path/to/project          # menu chọn (dùng gum nếu có, không thì prompt thường)
~/agent-kit/kit list                           # xem các stack, framework, module, docker service
```

Chạy không cần hỏi (CI, script):
```bash
kit init . --stack php::laravel --modules ba,sa,docker,codegraph --services mysql,redis --yes
kit init . --stack java-maven:backend:spring,node:frontend:react --services postgres,redis --lang en --yes
kit add serena            # thêm module vào dự án đã cài
kit doctor . --run        # kiểm tra tool/config và chạy thử các cổng chất lượng
```
`--yes` = chấp nhận mặc định, kể cả cài dev-deps và chạy setup của module. Có thể tắt bằng `--no-deps` và `--no-setup`. `install.sh` cũ vẫn chạy được (gọi `kit init`).

## 0. Kit gồm gì

```
agent-kit/
├── kit                       CLI: init · add · doctor · list
├── core/                     luôn được cài: AGENTS.md, .agent/ (rules/core, scripts, hooks, tasks, memory), .claude/, .githooks/, CI
├── stacks/<stack>/           chỉ stack được chọn mới được cài
│   ├── stack.yaml            detect, lệnh cmd_*, dev_deps, cổng app
│   ├── rules.md              chuẩn cộng đồng + tool nào ép rule nào  → .agent/rules/stack/<stack>.md
│   ├── files/                config tool thật (copy vào thư mục component)
│   ├── snippets/             đoạn cần merge tay (pom plugins, ArchitectureTest…) → .agent/stack/<stack>/snippets/
│   ├── docker/Dockerfile     multi-stage, non-root
│   ├── ci.yml                bước setup runtime cho GitHub Actions
│   └── frameworks/<fw>/      overlay: framework.yaml (ghi đè lệnh), rules.md, files/, docker/
└── modules/<module>/         tuỳ chọn: module.yaml, files/, project.add (thêm cmd_*), gitignore.add, setup.sh
```

### Stack và chuẩn được áp dụng
| Stack | Chuẩn cộng đồng | Format | Lint / types | Kiến trúc (`kit-run arch`) | Framework overlay |
|---|---|---|---|---|---|
| `php` | PSR-1, PSR-4, **PER-CS 2.0** (thay PSR-12) | PHP-CS-Fixer `@PER-CS2.0` | PHPStan lv 8 + strict-rules, `composer validate` | deptrac | `laravel` (Pint, Larastan), `symfony` (`@Symfony`, phpstan-symfony) |
| `java-maven` / `java-gradle` | Google Java Style, Effective Java | Spotless + google-java-format | Checkstyle `google_checks` | ArchUnit `ArchitectureTest` | `spring` (constructor injection, layering, Flyway, ProblemDetail) |
| `node` | TS strict | Prettier | ESLint `strict-type-checked`, `tsc --noEmit` | dependency-cruiser | `react`, `nestjs` |
| `python` | PEP 8 / 257 / 484 | Ruff format | Ruff (E,F,I,N,D,B,S,…), mypy `--strict` | import-linter | `fastapi`, `django` |
| `go` | Effective Go, Code Review Comments | gofmt, gofumpt, goimports | golangci-lint v2, `go vet`, `-race` | depguard (snippet) | — |
| `rust` | Rust API Guidelines | rustfmt | clippy `-D warnings` + `[lints]` | — | — |
| `dotnet` | .NET coding conventions | `dotnet format` + `.editorconfig` | Roslyn analyzers, warnings-as-errors | NetArchTest (snippet) | — |
| `generic` | — | — | — | — | điền trong kit-onboard |

Monorepo: mỗi component là `path=stack+framework`. Lệnh được ghép kiểu `(cd backend && …) && (cd frontend && …)`, nên `kit-run lint` chạy cho tất cả. Kit tự nhận theo lockfile: pnpm/yarn/npm, uv, có `mvnw`/`gradlew` hay không.

### Module
| Module | Mặc định | Cài thêm |
|---|---|---|
| `ba` | ✔ | `kit-ba` theo BABOK (stakeholder, as-is/to-be swimlane, use case, sequence, state, ERD, story map, RTM), skill `kit-diagram`, template trong `docs/ba/_templates/`, `kit-run docs` render và kiểm tra mọi sơ đồ Mermaid/PlantUML (mmdc/plantuml, hoặc qua Docker) |
| `sa` | ✔ | `kit-sa` + agent `solution-architect`: kịch bản chất lượng, so sánh phương án, arc42-lite `docs/architecture/SOLUTION.md`, C4 context/container/deployment, `sizing.md` (sizing + chi phí), ADR |
| `docker` | ✔ | Dockerfile cho từng component, `compose.yaml` sinh từ catalog (postgres, mysql, redis, rabbitmq, kafka, minio, mailpit, keycloak, observability), `kit-run up/down/logs`, skill `kit-docker` |
| `codegraph` | ✔ | `codegraph init` (index + MCP), rule `code-intelligence.md`, `.codegraph/` vào gitignore |
| `openspec` | ✔ | [OpenSpec](https://github.com/Fission-AI/OpenSpec) 2.1.1 (ghim version, chạy qua `kit-openspec`, tắt telemetry) + schema **`kit-flow`**: proposal có Source/Clarifications, design có Impact & reuse/Data model/API/Test plan, tasks mỗi nhóm = 1 kit task, test trước. Cần Node ≥ 20.19 |
| `serena` | | thêm Serena (LSP qua MCP, chạy bằng uvx) vào `.mcp.json` |

### Rules nằm ở đâu
```
.agent/rules/
  core/      git-workflow · security · testing · error-handling · logging · api-design · database (+ code-intelligence)
  stack/     <stack>.md + <framework>.md   — chuẩn cộng đồng, mỗi rule ghi tool ép nó
  project/   luật riêng của dự án (kit-onboard / kit-sa / người viết)
.claude/rules/stack-*.md   — chỉ trỏ tới file trên, có `paths:` nên Claude Code chỉ nạp khi đụng đúng loại file
```
Thứ tự ưu tiên: `project` > `stack` > `core`. Tool (formatter, linter, arch test) thắng mọi văn bản. Khi agent sửa `.agent/rules/**` hoặc file config tool (phpstan.neon, eslint.config…), hook sẽ hỏi người duyệt.

### Quy trình chuẩn cho mọi task (`.agent/rules/core/workflow.md`)

```
UC/US (docs/ba) ─▶ OpenSpec change: proposal ─▶ specs ─▶ design ─▶ tasks      (kit-plan, kit-new change)
                         │ Source + Clarifications (hỏi rõ trước)   │ mỗi nhóm = 1 TASK
                         ▼                                          ▼
 kit-task start ─▶ 1 Hiểu ─▶ 2 Hỏi rõ ─▶ 3 Giải pháp (codegraph: tái sử dụng) ─▶ 4 Test trước (đỏ) ─▶ 5 Code + checkpoint
               ─▶ 6 Verify ─▶ 7 Tài liệu (Result + living docs) ─▶ 8 kit-task finish
                                                                    │ verify gates → kit-run check → archive change vào openspec/specs → PR
```
- `kit-task verify` **chặn bằng máy**: §1 Understand, §2 Clarifications, §3 Solution, §7 Result phải có nội dung; mọi AC đã tick; `docs/qa/TASK-NNN.md` có đủ mọi AC; change OpenSpec hợp lệ `--strict`.
- Task cuối của một change sẽ **archive change vào `openspec/specs/` trong cùng PR** với code. Spec luôn khớp với code đã merge.
- Tài liệu kế hoạch (BA, ADR, change) viết trên `develop` được `kit-task start` mang sang nhánh task. Code chưa commit thì vẫn bị chặn.
- Task done được chuyển vào `.agent/tasks/archive/YYYY-MM/` để agent không đọc lịch sử như sự thật hiện tại.

### Tài liệu nằm ở đâu (`.agent/rules/core/documentation.md`, bản đồ: `docs/README.md`)
| Loại | Ở đâu |
|---|---|
| Hệ thống đang làm gì (living) | `openspec/specs/` |
| Cấu trúc, dữ liệu, hạ tầng (living) | `docs/architecture/`, `docs/api/` |
| Nghiệp vụ | `docs/ba/` (use case, story mỗi cái một file) |
| Thay đổi đang làm | `openspec/changes/<change>/` |
| Nhật ký thực thi một task | `.agent/tasks/TASK-NNN-*.md` + `docs/qa/TASK-NNN.md` |
| Quyết định | `docs/adr/` |

### Scaffold bằng script (`.agent/scripts/kit-new`), không để AI tự sinh khung
`kit-new task|change|testplan|adr|usecase|story|doc`. Template nằm ở `.agent/templates/`, schema OpenSpec ở `openspec/schemas/kit-flow/`. Tự đánh số (UC-NN, US-NN, ADR-NNNN, TASK-NNN), slug tiếng Việt bỏ dấu đúng (`Chào người dùng` → `chao-nguoi-dung`).

## 1. Kiến trúc: 4 lớp

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 1. NGỮ CẢNH & BỘ NHỚ (file trong repo, harness nào cũng đọc được)            │
│    AGENTS.md (luật) · .agent/context/ (mục tiêu, kiến trúc, convention)      │
│    .agent/memory/ (STATE, DECISIONS, LESSONS) · .agent/tasks/ (1 file/task)  │
├──────────────────────────────────────────────────────────────────────────────┤
│ 2. QUY TRÌNH (playbook = .claude/skills/*/SKILL.md + 6 sub-agent)            │
│    onboard → BA → plan → task → testcases → review → security → handoff     │
├──────────────────────────────────────────────────────────────────────────────┤
│ 3. HÀNG RÀO BẮT BUỘC (máy chặn, không phụ thuộc agent có "nghe lời" không)   │
│    Claude hooks (chặn lệnh/file) · git hooks (mọi harness + người)            │
│    · CI (secrets, lint, test, SAST, dependency scan)                         │
├──────────────────────────────────────────────────────────────────────────────┤
│ 4. GITFLOW & ROLLBACK (.agent/scripts/kit-task)                              │
│    nhánh theo task · restore point mỗi checkpoint · backup branch · revert PR │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 2. Cách từng yêu cầu được giải quyết

| Yêu cầu | Cơ chế trong kit |
|---|---|
| Agent đủ ngữ cảnh, không đi sai hướng | `PROJECT.md` (mục tiêu, non-goal), `ARCHITECTURE.md`, `docs/ba/`. Mỗi task phải trỏ về một goal (`goal_ref`). Playbook `kit-plan` bắt có AC trước khi code |
| Bộ nhớ qua các session | `STATE.md` (≤ 40 dòng, ghi đè), *Progress log* + *Handoff notes* trong file task, `LESSONS.md`, ADR. Tất cả là file trong git, không phụ thuộc chat |
| Session không phình context | Mỗi session chỉ làm một task. Hook `SessionStart` chỉ nạp gói ngữ cảnh ngắn (`kit-context --brief`). Phần còn lại đọc khi cần. Việc đọc nhiều giao cho sub-agent (`explorer`, `qa-engineer`…). Hết task hoặc context nặng thì chạy `kit-handoff` rồi mở session mới, sau đó `kit-resume` |
| Dự án đang có | `install.sh` không ghi đè file của bạn (ghi `*.kit-new`, merge `settings.json`), rồi playbook `kit-onboard` phân tích code, điền context, kiểm tra lệnh build/test, ghi baseline |
| Chặn lỗi coding convention | Chuẩn cộng đồng của từng stack (`.agent/rules/stack/`) + file config tool thật. `kit-run format_check lint typecheck arch` chạy ở pre-push, `kit-task finish` và CI. Commit message theo Conventional Commits (hook `commit-msg` + CI) |
| Không đẩy env / secret lên | `.gitignore` chặn sẵn. Claude hook chặn đọc, in, copy file `.env`/key. Pre-commit quét secret (gitleaks nếu có, kèm bộ regex riêng). CI quét toàn repo và lịch sử commit của PR. Lệnh deploy/publish/infra luôn hỏi người duyệt |
| Quy trình an toàn bảo mật | Playbook `kit-security` + `checklists/security.md` (dựa trên OWASP), sub-agent `security-reviewer`, CI có semgrep và trivy, `docs/security/THREAT-MODEL.md` |
| Agent tự viết test case | Playbook `kit-testcases` + sub-agent `qa-engineer`: thiết kế test case (boundary, negative, security…) vào `docs/qa/TASK-NNN.md` rồi tự động hoá. Mỗi AC phải có ít nhất một test |
| Gitflow, mỗi task một nhánh | `kit-task start` tạo `<type>/TASK-NNN-slug` từ `develop` (hotfix từ `main`). `main`/`develop` được bảo vệ ở cả 3 lớp: Claude hook, pre-commit/pre-push, branch protection trên GitHub |
| Backup + rollback khi agent làm sai | Mỗi `checkpoint` là một commit + tag `kit/TASK-NNN/cp-N`, và được push lên remote làm bản backup. `rollback` luôn tạo backup branch trước khi reset. Task đã merge thì dùng `kit-task revert` để tạo PR revert |
| Checklist chất lượng | `checklists/definition-of-done.md`, `code-review.md`, `security.md`, `release.md` + PR template |
| Docs & báo cáo hằng ngày | `docs/daily/YYYY-MM/YYYY-MM-DD.md`: phần tự động lấy từ git (commit, task, restore point), phần tóm tắt/vướng mắc/kế hoạch do agent viết. Có thêm `kit-daily --week` để tổng kết tuần |
| BA, phân tích, mô tả mục tiêu, plan | Module `ba`: brief, stakeholder, quy trình swimlane, use case, sequence/state/ERD, FR/NFR/US/AC, RTM, sơ đồ được kiểm tra render. `docs/plan/ROADMAP.md`, `docs/adr/` |
| Kiến trúc, hạ tầng, môi trường chạy | Module `sa` (phương án, C4, sizing, chi phí, ADR) + module `docker` (Dockerfile, compose.yaml từ catalog service) |

## 3. Luồng làm việc

```
 Ý tưởng / dự án có sẵn
        │
        ▼
 kit-onboard (code có sẵn)  hoặc  kit-ba (ý tưởng mới) ──▶ PROJECT.md, docs/ba/
        │
        ▼
 kit-sa (kiến trúc, hạ tầng, chi phí) ──▶ docs/architecture/, ADR ──▶ kit-docker (compose chạy local)
        │
        ▼
 kit-plan ──▶ ROADMAP.md + .agent/tasks/TASK-*.md (mỗi task vừa 1 session)
        │
        ▼   ┌───────────────────── 1 session = 1 task ─────────────────────┐
 kit-task start TASK-NNN  ──▶ nhánh feature/TASK-NNN-… + tag base           │
        │   code → kit-run check → kit-task checkpoint "…"   (lặp)          │
        │   sai hướng? → kit-task rollback [--to cp-N|base]  (có backup)    │
        │   kit-testcases → kit-review → kit-security → Definition of Done  │
        │   kit-task finish ──▶ check + push + PR vào develop               │
        │   kit-handoff ──▶ STATE.md + handoff notes + daily report         │
        └───────────────────────────────────────────────────────────────────┘
        ▼
 Người review và merge PR  ──▶ kit-task merged TASK-NNN  (sau này cần thì kit-task revert)
```

## 4. Lệnh

| Lệnh | Việc |
|---|---|
| `.agent/scripts/kit-run <step…>` | Chạy lệnh dự án theo `project.yaml`: `install format format_check lint typecheck arch test build audit secrets docs up down logs`, `check`, `ci` |
| `kit-task new "<title>" --change <c>` / `kit-task verify` | Task gắn với change OpenSpec / kiểm tra các gate của quy trình |
| `.agent/scripts/kit-new <kind> …` | Tạo tài liệu từ template: task, change, testplan, adr, usecase, story, doc |
| `.agent/scripts/kit-openspec <args>` | OpenSpec CLI đúng version ghim trong `project.yaml` (dùng `npx` nếu máy chưa cài) |
| `kit-task start TASK-NNN --worktree` | Task chạy trong worktree riêng `../<repo>-TASK-NNN` để nhiều agent làm song song |
| `kit-task worktrees` / `cleanup TASK-NNN` | Liệt kê worktree / gỡ worktree (từ chối nếu còn việc chưa commit) |
| `kit-task sync-gh [TASK-NNN\|--all]` / `pull-gh <issue#>` | Đồng bộ task ↔ GitHub Issues (label status/type/priority, tự đóng khi done, tuỳ chọn thêm vào GitHub Project) / tạo task từ issue |
| `.agent/scripts/kit-board [--json\|--html\|--open]` | Bảng kanban đọc trạng thái thật từ từng nhánh task; JSON cho UI/orchestrator; HTML tự chứa ở `.agent/local/board.html` |
| `.agent/scripts/kit-doctor [--run]` | Kiểm tra hook, rules, tool cần cho từng `cmd_*` theo từng component, tool của module |
| `.agent/scripts/kit-diagrams check\|export` | Render mọi sơ đồ Mermaid/PlantUML trong docs (module `ba`) |
| `.agent/scripts/kit-task new "<title>" [--type] [--priority]` | Tạo file task |
| `kit-task start TASK-NNN` | Tạo nhánh + restore point `base` (gọi lại thì tiếp tục nhánh cũ) |
| `kit-task checkpoint "<msg>"` | Commit + tag `cp-N` + push backup |
| `kit-task points` / `rollback [--to cp-N\|base]` | Xem và quay về restore point (luôn giữ backup branch) |
| `kit-task finish` | Quality gate + push + PR (`gh`) |
| `kit-task merged TASK-NNN` / `revert TASK-NNN` | Đánh dấu merge commit / tạo PR revert |
| `kit-task abandon` / `status` / `list` | Bỏ task (giữ backup) / trạng thái |
| `.agent/scripts/kit-context [--brief] [TASK-NNN]` | In gói ngữ cảnh, dán được vào **bất kỳ harness nào** (dsh, Codex…) |
| `.agent/scripts/kit-daily [date\|--week]` | Báo cáo ngày / tuần |
| `.agent/scripts/kit-secrets-scan [--staged\|--all\|--range a..b]` | Quét secret và file cấm |

## 5. Dùng với từng harness

- **Claude Code:** dùng được ngay. `CLAUDE.md` import `AGENTS.md`. Skills, sub-agents và hooks nằm trong `.claude/`.
  Gõ: *"chạy playbook kit-onboard"*, *"kit-plan cho tính năng X"*, *"làm TASK-003"*.
- **DeepSeek Harness / Codex / Cursor / OpenCode:** đọc `AGENTS.md`. Playbook là file Markdown, agent mở `.claude/skills/<tên>/SKILL.md` ra làm theo.
  Đầu session, dán output của `.agent/scripts/kit-context` vào. Hook của Claude không chạy ở đây, nhưng **git hooks và CI vẫn chặn** được commit/push sai, secret và lỗi lint/test.
- **Nhiều agent chạy song song:** mỗi agent một task, một nhánh. Có thể dùng `git worktree add ../app-TASK-007 feature/TASK-007-…`.

## 5b. Chạy song song, board và GitHub Issues

```
                 develop
                    │
   kit-task start TASK-007 --worktree ──▶ ../app-TASK-007  (agent A, nhánh feature/TASK-007-…)
   kit-task start TASK-008 --worktree ──▶ ../app-TASK-008  (agent B, nhánh feature/TASK-008-…)
                    │
   .agent/scripts/kit-board            ──▶ TODO · IN PROGRESS · REVIEW · DONE  (đọc file task trên từng nhánh)
   kit-task sync-gh --all              ──▶ GitHub Issues (+ Project nếu đặt gh_project)
   PR merge (Closes #N)                ──▶ issue tự đóng; kit-task cleanup TASK-007 gỡ worktree
```
- File task (`.agent/tasks/*.md`) là **nguồn gốc duy nhất**. Board, GitHub Issues và mọi UI sau này chỉ là lớp hiển thị. Schema frontmatter cố định, xem `.agent/tasks/README.md`.
- **Hook Stop** (Claude Code): khi agent sắp kết thúc lượt trên nhánh task mà code chưa commit làm fail `stop_checks` (mặc định `format_check lint`), hook chặn **một lần** và trả lỗi để agent sửa. Tắt bằng `stop_checks: none`.
- **Đường lên UI kiểu Vibe Kanban:** `kit-board --json` đã có đủ dữ liệu một UI cần (trạng thái, nhánh, worktree, issue, checkpoint, số file chưa commit). Một UI chỉ cần đọc JSON này và gọi `kit-task start --worktree` / `finish` để điều khiển agent. Không cần đổi format dữ liệu.

## 6. Thiết lập phía GitHub (bắt buộc để chặn ở server)

Settings → Branches → bảo vệ `main` và `develop`:
- Require a pull request before merging (≥ 1 approval nếu có team)
- Require status checks: `guard (secrets, branch, commits)`, `quality (…)`, `security (…)`
- Block force pushes, không cho xoá branch, bật "Do not allow bypassing the above settings"
- Settings → Code security: bật **Secret scanning + Push protection**

## 7. Tuỳ biến

- `.agent/project.yaml`: lệnh build/test, nhánh protected, `prepush_checks`, `stop_checks`, `gh_project`, `cmd_lint_staged`, `coverage_min`, `ask_commands_extra`.
  Agent sửa file này thì phải được người duyệt. Nhớ giữ `protected_regex` khớp với `main_branch`/`develop_branch`/`protected_extra`.
- Luật riêng của dự án: `AGENTS.md` §7 (ngắn) + `.agent/context/CONVENTIONS.md`.
  Luật quan trọng nên **biến thành test** (ArchUnit, dependency-cruiser, import-linter…) rồi ghi tên công cụ vào cột "Enforced by".
- Code intelligence: module `codegraph` (mặc định) và `serena` (tuỳ chọn). Playbook ưu tiên dùng chúng thay vì mở cả file.
- Người dùng có thể vượt qua chặn khi thật sự cần: `git commit --no-verify`, `KIT_ALLOW_PROTECTED_PUSH=i-am-human git push`. Agent thì bị hook chặn cả hai cách này.

## 8. Cấu trúc được cài vào dự án (ví dụ: php + laravel, module ba sa docker codegraph)

```
AGENTS.md  CLAUDE.md  .env.example  .gitignore(+)  .gitattributes(+)
pint.json  phpstan.neon.dist  deptrac.yaml  .editorconfig  Dockerfile  compose.yaml  .dockerignore   ← chỉ của stack/module đã chọn
.agent/
  project.yaml  kit.lock        lệnh (đã ghép theo component) · lựa chọn khi init
  rules/        core/ · stack/php.md, laravel.md · project/
  stack/php/snippets/           đoạn cần merge (kit-onboard làm)
  docker/catalog/               service để kit-docker thêm sau
  context/ memory/ tasks/ checklists/
  scripts/      kit-run · kit-task · kit-doctor · kit-diagrams · kit-context · kit-daily · kit-secrets-scan
  hooks/        guard-bash · guard-files · session-start (Claude Code)
.claude/  settings.json · rules/stack-php.md · skills/kit-* · agents/*
.githooks/ pre-commit · commit-msg · pre-push
.github/  workflows/ci.yml (setup đúng runtime) · PULL_REQUEST_TEMPLATE.md · ISSUE_TEMPLATE/
docs/     ba/ (+_templates) · architecture/ · plan/ · adr/ · qa/ · security/ · daily/
```

## 9. Mở rộng kit

- **Stack mới:** tạo `stacks/<tên>/stack.yaml` (`title detect globs app_port frameworks dev_deps cmd_*`, có thể dùng `inherit: <stack>` để mượn rules/files/snippets), thêm `rules.md`, `files/`, `ci.yml`, `docker/Dockerfile`, rồi thêm tên vào `DETECT_ORDER` trong `kit`.
- **Framework mới:** `stacks/<stack>/frameworks/<fw>/framework.yaml` (`detect`, các `cmd_*` cần ghi đè, `dev_deps` để thay hoặc `dev_deps_add` để cộng thêm, `exclude_files`, `app_port`), kèm `rules.md` và `files/`. Nhớ thêm tên vào `frameworks:` của stack.
- **Module mới:** `modules/<tên>/module.yaml` (`title default setup_desc`), `files/`, và nếu cần thì `project.add`, `gitignore.add`, `setup.sh`.
- **Docker service mới:** `modules/docker/catalog/<tên>.yml` (header `# title:` `# env:` `# volumes:` + fragment service thụt 2 khoảng trắng).

## 10. Giới hạn cần biết

- Hook của Claude Code chỉ chạy trong Claude Code. Với harness khác, lớp bảo vệ là git hooks và CI. Git hooks ở máy local có thể bị người tắt, nên **branch protection + CI mới là chốt chặn cuối**.
- Bộ quét secret dựng sẵn chỉ bắt các mẫu có độ tin cậy cao. Nên cài thêm `gitleaks` ở máy (`brew install gitleaks`), script sẽ tự dùng.
- Lệnh trong profile là mặc định hợp lý. Với Java, Rust, Go và .NET, một phần cấu hình phải merge vào file build (`pom.xml`, `Cargo.toml`…). Kit để sẵn ở `.agent/stack/<stack>/snippets/`, `kit-onboard` merge rồi chạy `kit-doctor --run` để xác nhận.
- Config tool đang giả định layout phổ biến (`src/`, `tests/`, `app/`). Dự án khác layout thì chỉnh đường dẫn trong config, **đừng nới rule**.
