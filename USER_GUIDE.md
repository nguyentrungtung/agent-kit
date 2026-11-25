# Cẩm nang Hướng dẫn Sử dụng agent-kit (User Guide từ A đến Z)

Chào mừng bạn đến với **agent-kit** — bộ khung harness tiêu chuẩn chuyên nghiệp dành cho việc phát triển phần mềm bằng AI coding agent (Claude Code, Gemini CLI, Antigravity, Cursor, Codex...).

Tài liệu này hướng dẫn bạn từng bước cách cài đặt, sử dụng thực tế và phối hợp nhịp nhàng với AI trong dự án hàng ngày.

---

## 📌 Mục lục
1. [Nguyên lý hoạt động](#1-nguyên-lý-hoạt-động)
2. [Cài đặt agent-kit lên máy cá nhân (Làm 1 lần duy nhất)](#2-cài-đặt-agent-kit-lên-máy-cá-nhân)
3. [Khởi tạo dự án mới hoặc áp dụng vào dự án có sẵn](#3-khởi-tạo-dự-án)
4. [Kịch bản thực hành mẫu từ A đến Z](#4-kịch-bản-thực-hành-mẫu-từ-a-đến-z)
5. [Kỹ thuật nâng cao: Tối ưu vận tốc AI](#5-kỹ-thuật-nâng-cao-tối-ưu-vận-tốc-ai)
6. [Quản trị & Khôi phục an toàn (Rollback)](#6-quản-trị--khôi-phục-an-toàn-rollback)
7. [Bảng tra cứu nhanh lệnh (Cheat Sheet)](#7-bảng-tra-cứu-nhanh-lệnh-cheat-sheet)

---

## 1. Nguyên lý hoạt động

* **Không copy nguyên cả repo agent-kit vào dự án:** Bạn **không cần** kéo toàn bộ repo vào dự án rồi đi xóa file thừa.
* **agent-kit hoạt động như một công cụ CLI:** Repo `agent-kit` nằm cố định tại một thư mục trên máy bạn (ví dụ: `~/agent-kit`). Khi bạn đứng ở dự án của mình và chạy lệnh `kit init`, công cụ sẽ **CHỈ cài đặt đúng ngôn ngữ, framework, quy tắc và module mà bạn chọn**.
* **Độc lập và an toàn:** Code dự án của bạn hoàn toàn tách biệt, không bị rác bởi các file thừa từ các ngôn ngữ khác.

---

## 2. Cài đặt agent-kit lên máy cá nhân

*(Chỉ cần thực hiện một lần duy nhất trên máy tính của bạn)*

### Bước 2.1: Clone repo về máy
Mở Terminal và clone repo về thư mục cá nhân:
```bash
git clone https://github.com/nguyentrungtung/agent-kit.git ~/agent-kit
```

### Bước 2.2: Tạo đường dẫn lệnh `kit` toàn cục
Tạo symlink vào `/usr/local/bin` để bạn có thể gọi lệnh `kit` ở bất kỳ thư mục nào:
```bash
sudo ln -sf ~/agent-kit/kit /usr/local/bin/kit
```
Kiểm tra xem lệnh đã hoạt động chưa:
```bash
kit list
```
*(Nếu hiển thị danh sách các stack và module là bạn đã cài đặt thành công!)*

---

## 3. Khởi tạo dự án

### Trường hợp A: Tạo một dự án mới hoàn toàn (Greenfield)
```bash
# 1. Tạo thư mục dự án và khởi tạo git
mkdir ~/Desktop/my-new-app && cd ~/Desktop/my-new-app
git init

# 2. Khởi tạo agent-kit (menu tương tác sẽ hiện ra để bạn chọn stack, framework, database...)
kit init .
```

### Trường hợp B: Áp dụng vào dự án đã có mã nguồn sẵn (Brownfield)
`kit init` rất thông minh: nó tự động phát hiện ngôn ngữ/framework qua file cấu hình (package.json, pom.xml, composer.json...) và **không bao giờ ghi đè file code cũ** của bạn (nếu trùng file, nó sẽ sinh file `*.kit-new` để bạn đối chiếu):
```bash
cd /path/to/du-an-hien-tai
kit init .
```
Với repo có sẵn kit chỉ **thêm** những gì repo chưa có: tự nhận Git host (GitHub hay GitLab tự host), chạy trunk-based nếu repo chưa có `develop`, không đặt cấu hình trùng với cái đã có ở thư mục cha, không chiếm hook Husky/lefthook, và cảnh báo nếu `.gitignore` của bạn đang ẩn file của kit. Chi tiết: README mục "Áp dụng vào repo có sẵn". Sau khi cài, mở agent và nói **"run the kit-onboard playbook"**; nó lấy lệnh build/test từ file CI của repo làm chuẩn.

### Chạy nhanh không cần hỏi qua menu (Dành cho script hoặc CI):
```bash
# Dự án Node + React
kit init . --stack node::react --preset app --yes

# Dự án Java Spring Boot + PostgreSQL + Redis
kit init . --stack java-maven::spring --services postgres,redis --yes

# Dự án Python FastAPI
kit init . --stack python::fastapi --yes

# Repo dữ liệu trên GitLab tự host: Python (ingestion/) + dbt (transform/), trunk-based, giữ hook cũ
kit init . --preset data --provider gitlab --flow trunk --hooks keep --yes
```

---

## 4. Kịch bản thực hành mẫu từ A đến Z

Sau khi chạy `kit init`, trong dự án của bạn đã có file [AGENTS.md](file:///Users/tungnt/Desktop/MBFS-REAL/agent-kit/core/AGENTS.md) và thư mục `.agent/`. Hãy mở AI coding agent (Claude Code, Gemini CLI, Antigravity, Cursor...) và thực hiện theo 4 giai đoạn sau:

### Giai đoạn 1: Phân tích & Thiết kế kiến trúc (BA ➔ SA ➔ Planner)
Đừng vội để AI code ngay! Hãy yêu cầu AI phân tích yêu cầu nghiệp vụ và chốt giải pháp kiến trúc:

#### 1.1. BA phỏng vấn làm rõ yêu cầu (Elicitation & Q&A)
Khi bạn đưa ra một yêu cầu mới (ví dụ: *"làm tính năng đăng nhập, đăng ký"*), AI BA sẽ **chủ động phỏng vấn bạn 3–5 câu hỏi then chốt** trước khi viết tài liệu:
* Ai sử dụng? (Người dùng cuối, Admin, Khách vãng lai).
* Nền tảng nào? (Chỉ Web SSR, hay Web SPA + Mobile App tương lai).
* Phương thức gì? (Email/Password, OTP SMS, hay Google/Apple OAuth2).
* Chính sách bảo mật & Điều kiện biên? (Khóa khi sai 5 lần, thời hạn phiên, 2FA).

> Quy tắc chung (mọi dự án, không chỉ auth): BA **bắt buộc** hỏi một lượt **3–6 câu đóng** (có lựa chọn + đáp án đề xuất) trước khi viết tài liệu,
> chọn từ 6 chiều: **A** Mục tiêu · **B** Người dùng & quyền · **C** Phạm vi · **D** Dữ liệu & quy tắc · **E** Quy mô & chất lượng · **F** Bối cảnh & ràng buộc
> (vòng đầu phủ ít nhất A, B, C). Câu chưa có người trả lời được ghi `ASSUMPTION:`; chỉ con người đổi thành `CONFIRMED:` — trước đó `kit-task finish` bị chặn.

Sau đó, BA chuẩn hóa yêu cầu theo **cú pháp EARS** (Event-driven, State-driven, Unwanted behavior), **phác thảo Wireframe (khung giao diện) & 4 trạng thái UI then chốt** (Empty, Loading, Error, Success), và xuất ra gói **Architecture Hand-off Packet** cho SA.
```bash
# Tạo tài liệu Use Case
.agent/scripts/kit-new usecase "Dang ky nguoi dung"

# Tạo User Story kèm Wireframe, 4 trạng thái UI và Acceptance Criteria (Given-When-Then chuẩn EARS)
.agent/scripts/kit-new story "Dang ky bang Email va Mat khau" --uc UC-01
```

#### 1.2. SA thiết kế giải pháp & Sơ đồ kết nối (Sequence Diagram, ADR & Design System)
Sau khi có đầu vào từ BA, Solution Architect (role `sa`) sẽ giải quyết câu hỏi **HOW**:
* **Phỏng vấn kiến trúc trước (4–6 câu):** số dev/team, có cần deploy/scale độc lập không, tải 12 tháng tới, RTO/RPO, độ phức tạp nghiệp vụ, ngân sách & năng lực vận hành
  → chấm điểm các phương án (modular monolith / layered / microservices…) rồi ghi ADR. Microservices chỉ khi đủ: nhiều team + ranh giới đã ổn định + cần deploy/scale độc lập + có DevOps.
* **Tách module** theo bounded context (mỗi module sở hữu dữ liệu riêng, phụ thuộc không vòng) → `.agent/rules/project/modules.md`, được arch test (`kit-run arch`) cưỡng chế.
* **Cấu trúc thư mục BE + FE** → `docs/architecture/project-structure.md` (module backend ↔ feature frontend 1:1, type API sinh từ `openapi.yaml` bằng `kit-run apigen`).
* **Pattern & thuật toán cho 3–5 quy tắc khó nhất** (tính giá, xếp lịch, phân bổ, tồn kho đồng thời…) → `SOLUTION.md` §7b, tra cứu ở `.agents/skills/kit-sa/PATTERNS.md`; mỗi pattern phải gắn với một yêu cầu cụ thể.
* Nếu ứng dụng chỉ chạy trên Web: Chọn **Session Cookie (HttpOnly)** để chống tấn công XSS.
* Nếu có Mobile App hoặc SPA: Chọn **OAuth2 PKCE + JWT Token** (Access token ngắn hạn + Refresh token xoay vòng).
* Vẽ **Sơ đồ Sequence (Mermaid)** mô tả cách Client $\leftrightarrow$ API Gateway $\leftrightarrow$ Auth Service $\leftrightarrow$ DB/Redis tương tác với nhau.
* Thiết lập **Frontend Architecture & Living Design System (`docs/architecture/ui-design-system.md`)**: Thư viện component (Tailwind CSS, shadcn/ui), Design Tokens (bảng màu, font chữ, dark mode), Responsive (<640px, <1024px, ≥1024px) và Accessibility (WCAG 2.1 AA).
* Ghi quyết định vào **ADR** (`.agent/scripts/kit-new adr "Chon co che Authentication"`).

#### 1.3. Lập kế hoạch OpenSpec & Chia Task (`kit-plan`)
Gói toàn bộ đặc tả vào OpenSpec và chia thành các Task cỡ vừa (Size M):
```bash
.agent/scripts/kit-new change register-flow "User Registration Flow"
```

---

### Giai đoạn 2: Tạo Task và Bắt đầu làm việc (Vai trò Full-stack Developer)
Mỗi tính năng được phân rã thành các Task vừa vặn (Size M: 150–350 dòng code) do **Full-stack Developer** thực hiện:
* **Lát cắt dọc trọn vẹn (Vertical Slice):** 1 Developer agent chịu trách nhiệm triển khai từ Database $\to$ Backend Logic $\to$ API Endpoint $\to$ Frontend UI Component $\to$ Automated Test.
* **Không tách riêng BE và FE:** Loại bỏ hoàn toàn tình trạng lệch hợp đồng API, không cần mock data tạm thời, tiết kiệm ~65% token và không gây tắc nghẽn giữa các agent.
```bash
# 1. Tạo Task mới gắn với đề xuất thay đổi (gắn thẻ topic để nạp bài học LTM)
.agent/scripts/kit-task new "Xay dung API va UI dang ky tai khoan" --change register-flow --priority P1 --tags "auth, ui"

# 2. Bắt đầu Task (Hệ thống tự động tạo nhánh git: feature/TASK-001-...)
.agent/scripts/kit-task start TASK-001
```

---

### Giai đoạn 3: Thiết kế Test Case & AI Viết code (TDD + Checkpoint)

#### 3.1. Thiết kế ca kiểm thử: Bộ 6 Ca Kiểm Thử Bắt Buộc (Core 6 Test Matrix)
Trước khi viết mã nguồn, QA Engineer / AI phải tạo tài liệu kiểm thử (`.agent/scripts/kit-new testplan TASK-NNN` $\to$ `docs/qa/TASK-NNN.md`) và phân tích **tối thiểu 5–6 góc độ kiểm thử** chuẩn mực:

1. **TC-01 (Happy Path - Luồng chuẩn):** Dữ liệu hợp lệ, trạng thái sẵn sàng $\to$ Kết quả thành công (200/201, dữ liệu ghi vào DB).
2. **TC-02 (Boundary & Limits - Giá trị biên):** Độ dài tối thiểu, tối đa, số 0, số âm, khoảng trắng đầu/cuối được trim (BVA).
3. **TC-03 (Negative & Validation - Dữ liệu sai):** Thiếu trường bắt buộc, sai định dạng email/regex, trùng lặp tài nguyên (409 Conflict).
4. **TC-04 (Security & Access Control - Phân quyền):** Chưa đăng nhập (401), không đủ quyền (403), cố tình sửa dữ liệu của user khác (IDOR).
5. **TC-05 (State Transition & Business Rules - Trạng thái & Nghiệp vụ):** Tài khoản bị khóa mà cố đăng nhập, đơn hàng đã hủy mà cố thanh toán.
6. **TC-06 (Resilience & Concurrency - Bất biến & Ngoại lệ):** Gửi 2 request trùng nhau cùng lúc (Idempotency key), mạng timeout.
7. **UI & Accessibility (dành cho tính năng có màn hình):** Kiểm tra hiển thị responsive (Mobile vs Desktop), 4 trạng thái UI (Empty, Loading, Error, Success), điều hướng phím Tab và nhãn `aria-*` (chuẩn WCAG 2.1 AA).

#### 3.2. Cấu trúc bảng Test Case đúng chuẩn:
```markdown
| ID | AC / Scenario | Type | Precondition | Test Data / Steps | Expected Result | Automated In | Status |
|---|---|---|---|---|---|---|---|
| TC-01 | US-01 AC1 (Happy) | unit | DB rỗng | Input: name="An" | Trả về: "Xin chào, An" | src/greeting.test.ts::testValid | passed |
| TC-02 | US-01 AC2 (Boundary) | unit | - | Input: name="" | Trả về: "Xin chào, bạn" | src/greeting.test.ts::testEmpty | passed |
| TC-03 | US-01 AC3 (Trim) | unit | - | Input: name="  An  " | Trả về: "Xin chào, An" | src/greeting.test.ts::testTrim | passed |
```

#### 3.3. Quy trình TDD và Lưu tiến độ (In-task Checkpoints):
1. AI viết test trước $\to$ Chạy test thất bại (Red - đúng kỳ vọng).
2. AI viết mã nguồn tối thiểu để test vượt qua (Green) $\to$ Chạy kiểm tra:
   ```bash
   .agent/scripts/kit-run check
   ```
3. Lưu mốc thành công bằng Checkpoint (tạo tag git backup tự động):
   ```bash
   .agent/scripts/kit-task checkpoint "Hoan thanh schema validate DTO va test do"
   ```
4. Tiếp tục viết logic xử lý, kiểm tra xanh và lưu tiếp checkpoint:
   ```bash
   .agent/scripts/kit-task checkpoint "Hoan thanh xu ly business logic service"
   ```

---

### Giai đoạn 4: Hoàn thành Task & Mở Pull Request
Khi toàn bộ tiêu chí chấp nhận (AC) đã đạt:
```bash
# 1. Chạy 7 cổng kiểm tra tự động bằng máy
.agent/scripts/kit-task verify

# 2. Hoàn tất task (Tự chạy test, format code, push remote và mở PR)
.agent/scripts/kit-task finish
```

Sau khi Pull Request được review và merge vào nhánh `develop`:
```bash
# Đánh dấu task Done và tự động chuyển vào thư mục lưu trữ archive/
.agent/scripts/kit-task merged TASK-001
```

---

## 5. Kỹ thuật nâng cao: Tối ưu vận tốc AI

Để AI làm việc với tốc độ nhanh nhất mà không gặp lỗi:

### 1. Quy tắc kích thước Task (Sweet Spot) & Vai trò Full-stack Developer
* **Tuyệt đối không chia vụn theo tầng kỹ thuật (Horizontal):** Không chia riêng task Entity, task DTO, task Controller, hay tách riêng task Backend và task Frontend.
* **Chia theo lát cắt dọc (Vertical Slice - Size M: 150–350 LOC):** 1 task giải quyết trọn vẹn 1 tính năng/endpoint gồm cả Database Migration + Logic Nghiệp vụ + API Endpoint + UI Component + Test tự động.
* **Tại sao không nên tạo role FE và Design riêng biệt?**
  * Tách riêng role FE/Design gây ra hiện tượng **Agent Churn & Token Bloat** (tốn 60-70% token chỉ để bàn giao và tóm tắt lại ngữ cảnh cho nhau).
  * Gây ra lỗi **Lệch Interface (Contract Drift)** giữa BE và FE do 2 agent tự suy đoán khác nhau.
  * **Giải pháp chuẩn:** BA cung cấp Wireframe & 4 trạng thái UI $\to$ SA thiết lập Living Design System $\to$ **Full-stack Developer** tự code cả 2 đầu trong 1 task. Code khớp 100%, test ngay lập tức và tiết kiệm tối đa token.
* Dùng **`kit-task checkpoint`** để lưu các bước nhỏ bên trong task thay vì tạo nhiều task lặt vặt.

### 2. Chạy nhiều Agent song song bằng Git Worktrees
Khi có các task độc lập không phụ thuộc nhau (ví dụ: Task 1 làm Luồng Đăng nhập, Task 2 làm Luồng Xem Hồ sơ Người dùng):
```bash
# Terminal 1: Giao Task 1 cho Agent A trong thư mục riêng
.agent/scripts/kit-task start TASK-001 --worktree

# Terminal 2: Giao Task 2 cho Agent B chạy song song cùng lúc
.agent/scripts/kit-task start TASK-002 --worktree
```
Hai agent làm việc cùng lúc trên 2 thư mục làm việc độc lập, nhân đôi tốc độ dự án mà không lo xung đột mã nguồn.

### 3. Quy chuẩn viết tài liệu Markdown (Diátaxis Style Guide)
Tất cả tài liệu kỹ thuật trong dự án tuân thủ nghiêm ngặt tiêu chuẩn [docs/STYLEGUIDE.md](core/docs/STYLEGUIDE.md):
* **Khung Diátaxis:** Phân loại rõ ràng 4 loại: *Tutorials* (hướng dẫn người mới), *How-to* (xử lý tác vụ cụ thể), *Reference* (tra cứu API/lệnh), *Explanation* (kiến trúc & lý do).
* **Định dạng Markdown:** Duy nhất 1 thẻ H1, không nhảy cóc cấp tiêu đề, code block luôn có cú pháp ngôn ngữ, sơ đồ Mermaid được kiểm tra bằng `.agent/scripts/kit-run docs`.
* **Thông báo chuẩn GitHub:** Sử dụng `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`.

### 4. Quản lý Bộ nhớ Dài hạn bằng Thẻ chủ đề (Topic-based Long-Term Memory)
Thay vì sử dụng các cơ sở dữ liệu Vector DB cồng kềnh hay cài đặt thêm công cụ phức tạp, `agent-kit` sử dụng cơ chế **Zero Dependencies** thuần POSIX Shell và Markdown quy chuẩn:

* **Định dạng ghi nhớ bài học (`.agent/memory/LESSONS.md`):**
  Mỗi bài học hoặc sai lầm cần tránh được ghi trên 1 dòng duy nhất có gắn thẻ chủ đề `[topic]`:
  ```markdown
  - 2026-11-20 [auth] Storing JWT in localStorage is vulnerable to XSS → use HttpOnly Secure SameSite Cookie
  - 2026-11-21 [ci] sed -i '' fails on Linux GNU sed → use portable sed -i.bak ... && rm -f ...bak
  ```
  Các tag chuẩn gợi ý: `[auth]`, `[database]`, `[api]`, `[security]`, `[performance]`, `[docker]`, `[ci]`, `[test]`, `[frontend]`, `[data]`, `[architecture]`.

* **Gán thẻ khi tạo task mới:**
  ```bash
  .agent/scripts/kit-task new "Xây dựng JWT refresh token" --tags "auth, api"
  ```
* **Tự động cảnh báo trước khi viết code:**
  Khi chạy `.agent/scripts/kit-task start TASK-NNN`, script tự động đọc thẻ `tags` trong task, quét nhanh file `LESSONS.md` và in ra các bài học liên quan ngay trên terminal trước khi AI bắt tay vào code.
* **Tra cứu ngữ cảnh và quyết định theo chủ đề bất kỳ lúc nào:**
  ```bash
  .agent/scripts/kit-context --topic auth
  ```
  Lệnh này tự động tổng hợp: các bài học kinh nghiệm `[auth]` từ `LESSONS.md`, các quyết định thiết kế từ `docs/adr/`, và các task đang mở liên quan.

---

## 6. Quản trị & Khôi phục an toàn (Rollback)

Nếu trong quá trình làm việc AI đi sai hướng hoặc sinh code lỗi:

```bash
# Xem danh sách các điểm khôi phục đã tạo
.agent/scripts/kit-task points

# Quay về checkpoint an toàn gần nhất (hệ thống luôn giữ backup nhánh cũ)
.agent/scripts/kit-task rollback --to cp-1

# Hoặc quay hẳn về trạng thái ban đầu khi mới tạo task
.agent/scripts/kit-task rollback --to base

# Hủy bỏ task đang làm dở (không làm mất dữ liệu)
.agent/scripts/kit-task abandon
```

---

## 7. Bảng tra cứu nhanh lệnh (Cheat Sheet)

### Quản lý Dự án & Bộ công cụ (`kit`)
| Lệnh | Ý nghĩa |
|---|---|
| `kit list` | Xem danh sách toàn bộ Stack, Framework và Module hỗ trợ |
| `kit init .` | Khởi tạo harness cho dự án hiện tại |
| `kit add <module>` | Bổ sung thêm module (ví dụ: `kit add devops`, `kit add security`) |
| `kit doctor` | Kiểm tra xem máy có thiếu công cụ kiểm tra nào không |
| `kit tools install` | Tự động cài đặt các công cụ CLI còn thiếu |
| `kit upgrade .` | Nâng cấp bộ luật/script của agent-kit cho dự án (an toàn, không mất code) |

### Quản lý Vòng đời Task (`kit-task`)
| Lệnh | Ý nghĩa |
|---|---|
| `.agent/scripts/kit-task new "<tiêu đề>" [--tags "tag1, tag2"]` | Tạo một task mới (hỗ trợ gắn thẻ chủ đề như auth, api) |
| `.agent/scripts/kit-task start TASK-NNN` | Bắt đầu làm task (tạo nhánh git riêng, tự nạp bài học liên quan) |
| `.agent/scripts/kit-task start TASK-NNN --worktree` | Mở task trong một thư mục git worktree chạy song song |
| `.agent/scripts/kit-task checkpoint "<ghi chú>"` | Lưu mốc tiến độ (tự commit và tag backup) |
| `.agent/scripts/kit-task rollback` | Quay lui về checkpoint trước đó |
| `.agent/scripts/kit-task verify` | Chạy 7 cổng kiểm tra chất lượng bằng máy |
| `.agent/scripts/kit-task finish` | Hoàn tất task, kiểm tra toàn diện và mở Pull Request |
| `.agent/scripts/kit-task merged TASK-NNN` | Đánh dấu task đã được merge và lưu trữ |

### Theo dõi & Báo cáo
| Lệnh | Ý nghĩa |
|---|---|
| `.agent/scripts/kit-context --topic <chủ đề>` | Tra cứu ngữ cảnh nén, bài học kinh nghiệm và ADR theo chủ đề |
| `.agent/scripts/kit-trace` | Kiểm tra truy vết: id UC/US/BR/FR/ADR không tồn tại (agent bịa), story thiếu AC, module lệch `modules.md` |
| `.agent/scripts/kit-trace assumptions` | Liệt kê các `ASSUMPTION:` chưa được người xác nhận (người sửa thành `CONFIRMED: …` thì mới finish được) |
| `.agent/scripts/kit-board` | Xem bảng Kanban các task ngay trên Terminal |
| `.agent/scripts/kit-board --html` | Mở bảng Kanban trực quan trên trình duyệt Web |
| `.agent/scripts/kit-daily` | Tự động tổng kết báo cáo công việc trong ngày từ git commit |
| `.agent/scripts/kit-run check` | Chạy toàn bộ kiểm tra chất lượng (format, lint, test, arch) |
