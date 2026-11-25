# agent-kit — bộ khung harness cho AI coding agent (mọi ngôn ngữ)

Kit chứa **đủ mọi stack và module**. Lệnh `kit init` hỏi bạn chọn gì, rồi **chỉ cài phần đã chọn** vào dự án (mới hoặc đang có):
convention chuẩn cộng đồng của từng ngôn ngữ (kèm file config tool thật), rules, playbook, hook, CI, BA, SA, Docker.

👉 **Dành cho người mới bắt đầu:** Xem cẩm nang hướng dẫn thực hành từ A đến Z tại **[USER_GUIDE.md](USER_GUIDE.md)**.

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
| `python` | PEP 8 / 257 / 484 | Ruff format | Ruff (E,F,I,N,D,B,S,…), mypy `--strict` | import-linter | `fastapi`, `django`, **`airflow`** (DAG idempotent, test DAG integrity), **`pyspark`** (schema tường minh, partition, chispa) |
| `go` | Effective Go, Code Review Comments | gofmt, gofumpt, goimports | golangci-lint v2, `go vet`, `-race` | depguard (snippet) | — |
| `rust` | Rust API Guidelines | rustfmt | clippy `-D warnings` + `[lints]` | — | — |
| `dotnet` | .NET coding conventions | `dotnet format` + `.editorconfig` | Roslyn analyzers, warnings-as-errors | NetArchTest (snippet) | — |
| `dbt` | dbt Labs style guide, Kimball | SQLFluff (`templater = jinja` + dbt builtins, không cần kết nối) | `dbt parse`, `dbt build --target ci` (DuckDB) | **dbt_project_evaluator** (best-practice DAG) | contract `enforced` trên mart |
| `generic` | — | — | — | — | điền trong kit-onboard |

Monorepo: mỗi component là `path=stack+framework`. Lệnh được ghép kiểu `(cd backend && …) && (cd frontend && …)`, nên `kit-run lint` chạy cho tất cả. Kit tự nhận theo lockfile: pnpm/yarn/npm, uv, có `mvnw`/`gradlew` hay không.

### Module
| Module | Mặc định | Cài thêm |
|---|---|---|
| `ba` | ✔ | `kit-ba` theo BABOK (stakeholder, as-is/to-be swimlane, use case, sequence, state, ERD, story map, RTM), skill `kit-diagram`, template trong `docs/ba/_templates/`, `kit-run docs` render và kiểm tra mọi sơ đồ Mermaid/PlantUML (mmdc/plantuml, hoặc qua Docker) |
| `sa` | ✔ | Vai trò **tích hợp**: kịch bản chất lượng, hướng dẫn chọn kiểu kiến trúc (MVC + repository, HMVC, modular monolith, hexagonal, microservice, event-driven), so sánh phương án + ADR, C4, tích hợp, data model mức logic, khung chi phí. **Bàn giao** cho DevOps, AppSec, Data |
| `devops` | ✔ | `kit-devops` + agent `devops-engineer`: môi trường, IaC, CI/CD, chiến lược deploy, observability/SLO, backup/DR, sizing, runbook (`docs/platform/`). Gồm luôn phần Docker: Dockerfile từng stack, `compose.yaml` từ catalog, `kit-run up/down/logs`. **`kit-run ops`** = hadolint, actionlint, shellcheck, compose config, terraform, kubeconform (dùng tool trên máy hoặc image Docker ghim version). `docker` là tên cũ, vẫn dùng được |
| `security` | ✔ | `kit-appsec` + agent `security-architect`: threat model (DFD + STRIDE), chọn mức ASVS, yêu cầu bảo mật thành scenario OpenSpec, thiết kế authN/Z, sổ dữ liệu cá nhân theo **Luật 91/2025/QH15 + NĐ 356/2025/NĐ-CP**, SBOM (`kit-run sbom`), DAST baseline (ZAP, chỉ cho local/staging) |
| `codegraph` | ✔ | `codegraph init` (index + MCP), rule `code-intelligence.md`, `.codegraph/` vào gitignore |
| `openspec` | ✔ | [OpenSpec](https://github.com/Fission-AI/OpenSpec) 2.1.1 (ghim version, chạy qua `kit-openspec`, tắt telemetry) + schema **`kit-flow`**: proposal có Source/Clarifications, design có Impact & reuse/Data model/API/Test plan, tasks mỗi nhóm = 1 kit task, test trước. Cần Node ≥ 20.19 |
| `data` | preset `data` | `kit-data` + agent `data-engineer`: kiến trúc dữ liệu (batch/stream, warehouse/lakehouse, medallion / staging→marts), mô hình Kimball (grain, SCD), **data contract** (`kit-new contract`), chất lượng dữ liệu viết test trước, lineage, backfill idempotent, PII; schema OpenSpec **`data-flow`** (`kit-new change <tên> --schema data-flow`); rule `.agent/rules/data/`; hook hỏi trước khi chạy vào prod (`--target prod`, `airflow dags backfill`) |
| `api` | preset `app` | `kit-api`: OpenAPI 3.1 **contract-first** (`docs/api/openapi.yaml`), Spectral (`kit-run api`: kebab-case path, camelCase operationId, lỗi RFC 9457), CI **chặn thay đổi phá vỡ tương thích** bằng oasdiff, Swagger UI (`--services swagger-ui`), bảng thư viện sinh docs theo framework |
| `eng-skills` | ✔ | 13 skill của [mattpocock/skills](https://github.com/mattpocock/skills) v1.3.2 (MIT, copy cố định, tiền tố `mp-`): `mp-grilling`/`mp-grill-with-docs` (hỏi rõ yêu cầu theo vòng), `mp-domain-modeling` (GLOSSARY + ADR), `mp-tdd`, `mp-diagnosing-bugs`, `mp-codebase-design`/`mp-improve-codebase-architecture` (module sâu), `mp-code-review` (2 chiều: chuẩn + spec), `mp-pr`, `mp-wizard` (script cho bước người làm), `mp-retro`, `mp-to-questionnaire`, `mp-writing-for-agents`. Đã gắn vào kit-task/kit-review/kit-ba/kit-sa/kit-devops/kit-handoff. Cập nhật: `scripts/vendor-mattpocock.py` |
| `serena` | | thêm Serena (LSP qua MCP, chạy bằng uvx) vào `.mcp.json` |

### Preset và vai trò
`kit init --preset app|data|platform|minimal` chọn sẵn bộ module (xem `kit list`); `--modules` để chỉnh tay. Ai làm gì, bàn giao thế nào: `.agent/rules/core/roles.md` (RACI).

```
kit-ba ─▶ kit-sa (giải pháp tổng thể) ─┬─▶ kit-devops (hạ tầng, CI/CD, vận hành)  → docs/platform/
                                        ├─▶ kit-appsec (thiết kế bảo mật, PII)     → docs/security/
                                        └─▶ kit-data   (dữ liệu phân tích)        → docs/data/
                                                    ─▶ kit-plan ─▶ kit-task (Full-stack Dev) …
```

### Tool trên máy: có thì dùng, thiếu mới cài
`kit tools <dir>` liệt kê các tool mà dự án cần (tính theo stack và module) và cho biết tool nào đã có. `kit tools <dir> install` **chỉ cài tool còn thiếu**, hỏi từng cái (brew → npm → go/cargo/pipx). Tool đã có thì giữ nguyên, không đổi version. `kit init` làm bước này tự động (`--no-tools` để bỏ qua). Setup của module dùng `kit-tools ensure`, ví dụ codegraph: đã cài thì chỉ chạy `init` hoặc `sync`.

### Rules nằm ở đâu
```
.agent/rules/
  core/      workflow · documentation · roles · git-workflow · security · testing · error-handling · logging · api-design · database (+ code-intelligence)
  devops/    infrastructure · containers · ci-cd · observability          (module devops)
  security/  authn-authz · data-protection · supply-chain                 (module security)
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

### Kích cỡ Task & Tối ưu tốc độ AI (Bộ ba 3-in-1: Sweet Spot · Checkpoint · Worktree)
Để tránh tình trạng **task quá to** (làm AI quá tải context, ảo giác) hoặc **task quá vụn** (làm chậm tiến độ, tốn công review):
1. **Phân rã theo Lát cắt dọc (Vertical Slice - Size M: 150–350 dòng code) - Vai trò Full-stack Developer:**  
   `kit-plan` (role Planner) không chia task vụn theo từng tầng kỹ thuật (cấm chia riêng task Entity, task DTO, task Controller, cấm tách riêng BE và FE). Thay vào đó, một **Full-stack Developer** giải quyết trọn vẹn 1 tính năng/endpoint gồm: DB + Logic + API Endpoint + UI Component + Test tự động.
2. **Dùng Checkpoint bên trong Task (`kit-task checkpoint`):**  
   Trong một task cỡ M, AI hoàn thành từng bước nhỏ (schema $\to$ service $\to$ controller $\to$ test) thì tạo ngay checkpoint để giữ an toàn. Chỉ chạy `kit-task finish` và mở PR **một lần duy nhất** khi toàn bộ Acceptance Criteria đã đạt.
3. **Chạy song song bằng Worktree (`kit-task start --worktree`):**  
   Các task độc lập (không phụ thuộc nhau trong `docs/plan/ROADMAP.md`) được giao cho nhiều agent chạy song song trên các worktree riêng biệt (`../<repo>-TASK-NNN`), nhân đôi/nhân ba tốc độ phát triển.

### Thiết kế: data model và skeleton kiến trúc
- `kit-datamodel` (module sa): entity/aggregate, quan hệ 1-1/1-n/n-n, chuẩn hoá và khi nào phi chuẩn hoá, **quy tắc chọn ID** (BIGINT / UUIDv7 / public_id), constraint, index, multi-tenancy, migration expand → migrate → contract → `docs/architecture/data-model.md`.
- `kit-new module <tên> [--style layered|modular]`: sinh khung thư mục một module theo `arch_style` (ADR) cho Laravel, PHP, Spring (Modulith: `<base>/<module>/internal/{api,application,domain,infrastructure}`, cần `base_package`), NestJS/TypeScript, FastAPI. Mỗi thư mục có README ghi trách nhiệm của lớp. Cấu hình arch test tương ứng nằm ở `.agent/stack/<stack>/skeletons/`.

### Chất lượng được máy kiểm tra
| Kiểm tra | Lệnh | Ở đâu |
|---|---|---|
| Mỗi AC có test case, mỗi test case trỏ tới **test có thật** (`path::tên test`) hoặc ghi rõ `manual` + lý do | `kit-task verify` | trước `finish` |
| Coverage ≥ `coverage_min` (c8, pytest-cov, JaCoCo, `go tool cover`, cargo-llvm-cov, coverlet, Laravel `--min`) | `kit-run coverage` / `testcov` | CI |
| Code trùng lặp ≤ 3% (jscpd, mọi ngôn ngữ) | `kit-run dup` | CI |
| Độ phức tạp: ESLint `complexity`/`max-params`/`max-depth`, Ruff `C90`/`PLR`, PHPStan cognitive-complexity, PMD (Java), gocognit/gocyclo/funlen, CA1502 (.NET), clippy | `kit-run lint` | pre-push, CI |
| E2E + accessibility (Playwright + axe, React) · test tải k6 với ngưỡng SLO | `kit-run e2e` · `kit-run perf` | theo task / trước release |
Luật: `.agent/rules/core/clean-code.md` (tái sử dụng trước khi viết mới, module sâu, SOLID/KISS/YAGNI, khi nào dùng design pattern nào, anti-pattern). Checklist test theo loại thay đổi: `.agent/checklists/testing.md`.

### Phát hành và vận hành
| Việc | Lệnh / file |
|---|---|
| Version semver + CHANGELOG từ Conventional Commits | `kit-release plan` (xem trước) → `prepare` (nhánh `release/vX.Y.Z`, CHANGELOG, bump version) → `tag` sau khi merge vào main |
| CD: build image một lần, develop → staging, tag → production (duyệt tay) | `.github/workflows/cd.yml` (module devops; các bước deploy là TODO cho DevOps điền) |
| Cập nhật dependency tự động | `.github/dependabot.yml` sinh theo từng component (+ Docker, GitHub Actions) |
| Sự cố production + post-mortem không đổ lỗi | `kit-incident`, `kit-new postmortem "<tiêu đề>"` |
| Checklist release (gồm DAST/pentest trên staging, rollback) | `.agent/checklists/release.md` |
| Nâng cấp kit cho dự án đã cài | `kit upgrade <dir>`: file bạn chưa sửa thì cập nhật, file bạn đã sửa thì giữ nguyên + `*.kit-new`, file bạn đã xoá thì không tạo lại; thêm key mới vào `project.yaml` (dựa trên `.agent/kit.manifest`) |
| Lên 0.11.0 (anti-drift gates) | Task đang làm dở (không có `template: 2` trong front matter) giữ luật cũ — các gate mới (checklist §2, nguồn §1, assumption, review, tài liệu sống) chỉ áp dụng cho task tạo sau khi nâng cấp. Chạy `.agent/scripts/kit-trace` một lần để dọn id UC/US/BR/FR/ADR không tồn tại (kể cả id mẫu còn sót từ template BA). `ASSUMPTION:` trong `docs/ba/BRIEF.md` / `docs/architecture/SOLUTION.md` phải được người đổi thành `CONFIRMED:`. CI của dự án giờ chặn PR từ branch `feature/`·`fix/`·`hotfix/`·`refactor/` không có `TASK-NNN` — PR đang mở theo kiểu cũ cần đổi tên branch hoặc gắn task. Skeleton framework chuyển sang `.agent/stack/<stack>/skeletons/<framework>/`; skeleton bạn đã sửa được `kit upgrade` mang sang (bản kit ở `.kit-new`) |
| Kit tự test chính nó | `.github/workflows/kit-ci.yml`: lint shell + actionlint + gitleaks, `tests/smoke.sh` (init 14 dự án mẫu), `tests/e2e-workflow.sh` (luồng OpenSpec → task → finish) |

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
│ 2. QUY TRÌNH (playbook = .agents/skills/*/SKILL.md + sub-agent)              │
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
| Kiến trúc, hạ tầng, bảo mật thiết kế | Module `sa` (giải pháp tổng thể, ADR) → `devops` (hạ tầng, CI/CD, vận hành, Docker) · `security` (threat model, ASVS, PII) — RACI trong `.agent/rules/core/roles.md` |

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
| `.agent/scripts/kit-trace [--strict] · kit-trace assumptions` | Bước "analyze": mọi id UC/US/BR/FR/NFR/ADR được nhắc tới phải tồn tại; cảnh báo story thiếu UC/AC/AC âm, FR không có story, thư mục module lệch `modules.md`, `ASSUMPTION:` chưa được người xác nhận. Chạy trong `kit-run check`, CI và `kit-task verify` |
| `.agent/scripts/kit-review-bot [on\|off\|status]` | Bật/tắt review **tự động** của CodeRabbit cho repo (ghi `reviews.auto_review.enabled` vào `.coderabbit.yaml`, giữ nguyên các khoá khác). Tắt rồi vẫn gọi được khi cần: comment `@coderabbitai review` trên PR/MR; tạm dừng một PR/MR: `@coderabbitai pause`. Dùng được trên GitHub lẫn GitLab |
| `.agent/scripts/kit-board [--json\|--html\|--open]` | Bảng kanban đọc trạng thái thật từ từng nhánh task; JSON cho UI/orchestrator; HTML tự chứa ở `.agent/local/board.html` |
| `.agent/scripts/kit-doctor [--run]` | Kiểm tra hook, rules, tool cần cho từng `cmd_*` theo từng component, tool của module |
| `.agent/scripts/kit-diagrams check\|export` | Render mọi sơ đồ Mermaid/PlantUML trong docs (module `ba`) |
| `.agent/scripts/kit-task new "<title>" [--type] [--priority] [--tags]` | Tạo file task (hỗ trợ gắn thẻ chủ đề như auth, api) |
| `kit-task start TASK-NNN` | Tạo nhánh + restore point `base` (gọi lại thì tiếp tục nhánh cũ, tự nạp bài học liên quan) |
| `kit-task checkpoint "<msg>"` | Commit + tag `cp-N` + push backup |
| `kit-task points` / `rollback [--to cp-N\|base]` | Xem và quay về restore point (luôn giữ backup branch) |
| `kit-task finish` | Quality gate + push + PR (`gh`) |
| `kit-task merged TASK-NNN` / `revert TASK-NNN` | Đánh dấu merge commit / tạo PR revert |
| `kit-task abandon` / `status` / `list` | Bỏ task (giữ backup) / trạng thái |
| `.agent/scripts/kit-context [--brief] [--topic <chủ đề>] [TASK-NNN]` | In gói ngữ cảnh (lọc bài học, ADR theo topic), dán được vào **bất kỳ harness nào** (dsh, Codex…) |
| `.agent/scripts/kit-daily [date\|--week]` | Báo cáo ngày / tuần |
| `.agent/scripts/kit-secrets-scan [--staged\|--all\|--range a..b]` | Quét secret và file cấm |

## 5. Dùng với từng harness (Claude Code, Codex, Gemini CLI, Antigravity, dsh)

Một nguồn duy nhất cho mọi harness: luật ở `AGENTS.md`, playbook ở **`.agents/skills/`** (chuẩn Agent Skills), rule theo stack ở `.agent/rules/`.

| Harness | Luật | Playbook | Hook chặn của Claude |
|---|---|---|---|
| Claude Code | `CLAUDE.md` → `AGENTS.md`, `.claude/rules/` | `.claude/skills/` (symlink tới `.agents/skills/`), sub-agent `.claude/agents/` | ✅ |
| Codex | `AGENTS.md` | `.agents/skills/` | ❌ → git hooks + CI |
| Gemini CLI | `AGENTS.md` (qua `.gemini/settings.json` › `context.fileName`) | `.agents/skills/` (thư mục phải được `/trust`) | ❌ → git hooks + CI |
| Antigravity | `AGENTS.md`, `.agents/rules/stack-*.md` (`trigger: glob`) | `.agents/skills/` | ❌ → git hooks + CI |
| dsh / harness khác | `AGENTS.md` hoặc dán `kit-context` | `.agents/skills/` hoặc mở SKILL.md làm theo | ❌ → git hooks + CI |

OpenSpec được init cho `claude, codex, gemini, antigravity, dsh`. Ở harness không có hook, lớp chặn cuối là **git hooks + CI + branch protection**: commit, push và PR sai vẫn bị chặn, nhưng việc đọc file hay chạy lệnh thì không.

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

## 6. Thiết lập phía GitHub và sử dụng `gh` CLI (bắt buộc để chặn ở server)

Để đảm bảo an toàn tuyệt đối khi đẩy code qua `git push` hoặc `gh`:

### Cấu hình Branch Protection (`main` và `develop`)
Settings → Branches → bảo vệ `main` và `develop`:
- Require a pull request before merging (≥ 1 approval nếu có team).
- Require status checks: `guard (secrets, branch, commits)`, `quality (…)`, `security (…)`.
- Block force pushes, không cho xoá branch, bật "Do not allow bypassing the above settings".
- Settings → Code security: bật **Secret scanning + Push protection**.

### Đẩy code và tạo PR với GitHub CLI (`gh`)
```bash
# Đẩy nhánh task lên GitHub
git push -u origin feature/TASK-NNN-slug

# Tạo Pull Request vào develop (hoặc kit-task finish tự làm qua gh)
gh pr create --base develop --head feature/TASK-NNN-slug --title "feat: mô tả task" --body "Closes #issue_id"

# Kiểm tra trạng thái CI workflow trên GitHub Actions
gh run list --limit 5
gh run view <run_id> --log-failed
```

### Dùng GitLab thay cho GitHub

Đặt `git_provider: gitlab` trong `.agent/project.yaml` (để trống = đoán từ URL remote; GitLab tự host thì phải đặt).

| Phần | GitLab |
|---|---|
| Git hook (`pre-commit`, `commit-msg`, `pre-push`), hook Claude, `kit-trace`, `kit-task verify`, `kit-run check` | ✅ không phụ thuộc nhà cung cấp |
| `kit-task finish` | ✅ mở Merge Request bằng `glab mr create` (cần `glab auth login`); thiếu `glab` thì chỉ nhắc mở MR bằng tay. Chưa được thử với `glab` thật |
| `kit-task sync-gh` / `pull-gh` | ❌ chỉ GitHub Issues — trên GitLab lệnh báo lỗi rõ ràng; file task vẫn là nguồn gốc |
| `.github/workflows/ci.yml` (guard, quality, security), `cd.yml`, `dependabot.yml`, template issue/PR | ❌ chỉ GitHub Actions. Trên GitLab không chạy; **chưa có `.gitlab-ci.yml` đi kèm** — pipeline của bạn cần gọi các script của kit (`kit-run ci`, `kit-trace`, `kit-task verify`) để giữ các gate |
| Chặn merge ở server | Bật *Pipelines must succeed* và protected branch trên GitLab, tương đương branch protection |

**CodeRabbit** hỗ trợ GitLab (cloud và self-managed). Không muốn dùng hoặc đã có pipeline/review riêng: `.agent/scripts/kit-review-bot off`, commit `.coderabbit.yaml`.

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

## 10. Lưu ý quan trọng khi đưa vào dự án thực tế

> [!IMPORTANT]
> Mặc dù bộ khung đã hoàn chỉnh, khi đưa vào dự án thực tế bạn nên chú ý 3 điểm sau:
>
> 1. **Thiết lập Branch Protection trên GitHub (Rất quan trọng):**  
>    Các hook ở local (`.githooks/`) có thể bị lập trình viên bỏ qua nếu cố tình dùng terminal máy tính cá nhân (hoặc tham số `--no-verify`). Do đó, bạn **bắt buộc phải cấu hình Branch Protection Rules trên GitHub** (yêu cầu PR, chặn force push, bắt buộc pass các status check `guard`, `quality`, `security`) để làm chốt chặn bảo vệ cuối cùng trên server.
>
> 2. **Cài đặt các công cụ CLI hỗ trợ trên máy:**  
>    - Các công cụ bắt buộc: `git`, `jq`, `gh` (để tạo PR, đồng bộ task issue).  
>    - Các công cụ kiểm tra nâng cao: `gitleaks`, `spectral`, `hadolint`, `actionlint`, `jscpd` nên được cài qua `kit tools install` hoặc chạy qua container Docker để các lệnh kiểm tra trước khi push không bị báo thiếu tool.
>
> 3. **Môi trường hoạt động của Hooks:**  
>    - Hệ thống hook chặn runtime (`guard-bash.sh`, `guard-files.sh`) tích hợp sâu nhất với **Claude Code** (chặn ngay lập tức trước khi thực thi shell command hoặc đọc/sửa file).  
>    - Khi làm việc với các harness khác như **Gemini CLI, Antigravity, Codex, Cursor**, lớp bảo vệ chính của bạn sẽ là **Git Hooks cục bộ (`.githooks/`) và GitHub Actions CI**.

## 11. Giới hạn cần biết

- Bộ quét secret dựng sẵn chỉ bắt các mẫu có độ tin cậy cao. Nên cài thêm `gitleaks` ở máy (`brew install gitleaks` hoặc `kit tools install`), script sẽ tự dùng.
- Lệnh trong profile là mặc định hợp lý. Với Java, Rust, Go và .NET, một phần cấu hình phải merge vào file build (`pom.xml`, `Cargo.toml`…). Kit để sẵn ở `.agent/stack/<stack>/snippets/`, `kit-onboard` merge rồi chạy `kit-doctor --run` để xác nhận.
- Config tool đang giả định layout phổ biến (`src/`, `tests/`, `app/`). Dự án khác layout thì chỉnh đường dẫn trong config, **đừng nới rule**.
