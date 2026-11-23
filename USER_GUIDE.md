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

### Chạy nhanh không cần hỏi qua menu (Dành cho script hoặc CI):
```bash
# Dự án Node + React
kit init . --stack node::react --preset app --yes

# Dự án Java Spring Boot + PostgreSQL + Redis
kit init . --stack java-maven::spring --services postgres,redis --yes

# Dự án Python FastAPI
kit init . --stack python::fastapi --yes
```

---

## 4. Kịch bản thực hành mẫu từ A đến Z

Sau khi chạy `kit init`, trong dự án của bạn đã có file [AGENTS.md](file:///Users/tungnt/Desktop/MBFS-REAL/agent-kit/core/AGENTS.md) và thư mục `.agent/`. Hãy mở AI coding agent (Claude Code, Gemini CLI, Antigravity, Cursor...) và thực hiện theo 4 giai đoạn sau:

### Giai đoạn 1: Phân tích & Lập kế hoạch (BA / Architecture)
Đừng vội để AI code ngay! Hãy yêu cầu AI phân tích yêu cầu nghiệp vụ:
```bash
# 1. Tạo tài liệu Use Case
.agent/scripts/kit-new usecase "Dang ky nguoi dung"

# 2. Tạo User Story kèm Acceptance Criteria (Given-When-Then)
.agent/scripts/kit-new story "Dang ky bang Email va Mat khau" --uc UC-01

# 3. Tạo đề xuất thay đổi chuẩn OpenSpec
.agent/scripts/kit-new change register-flow "User Registration Flow"
```
AI sẽ điền nội dung vào đề xuất: Tại sao làm? Thay đổi những gì? Thiết kế ra sao? Kế hoạch kiểm thử thế nào?

---

### Giai đoạn 2: Tạo Task và Bắt đầu làm việc
Mỗi tính năng được phân rã thành các Task vừa vặn (Size M: 150–350 dòng code):
```bash
# 1. Tạo Task mới gắn với đề xuất thay đổi
.agent/scripts/kit-task new "Xay dung API dang ky tai khoan" --change register-flow --priority P1

# 2. Bắt đầu Task (Hệ thống tự động tạo nhánh git: feature/TASK-001-...)
.agent/scripts/kit-task start TASK-001
```

---

### Giai đoạn 3: AI Viết code & Lưu mốc (In-task Checkpoints)
Áp dụng quy tắc kiểm thử trước (TDD) và lưu tiến độ thường xuyên:
1. AI viết test trước $\to$ Kiểm tra test thất bại (đúng kỳ vọng).
2. AI viết mã nguồn để test vượt qua $\to$ Chạy kiểm tra:
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

### 1. Quy tắc kích thước Task (Sweet Spot)
* **Tuyệt đối không chia vụn (Horizontal):** Không chia riêng task viết Entity, task viết DTO, task viết Controller.
* **Chia theo lát cắt dọc (Vertical Slice - Size M: 150–350 LOC):** 1 task giải quyết trọn vẹn 1 endpoint gồm cả Database + Service + Controller + Test.
* Dùng **`kit-task checkpoint`** để lưu các bước nhỏ bên trong task thay vì tạo nhiều task lặt vặt.

### 2. Chạy nhiều Agent song song bằng Git Worktrees
Khi có các task độc lập không phụ thuộc nhau (ví dụ: Task 1 làm API Backend, Task 2 làm Giao diện Frontend):
```bash
# Terminal 1: Giao Task 1 cho Agent A trong thư mục riêng
.agent/scripts/kit-task start TASK-001 --worktree

# Terminal 2: Giao Task 2 cho Agent B chạy song song cùng lúc
.agent/scripts/kit-task start TASK-002 --worktree
```
Hai agent làm việc cùng lúc trên 2 thư mục làm việc độc lập, nhân đôi tốc độ dự án mà không lo xung đột mã nguồn.

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
| `.agent/scripts/kit-task new "<tiêu đề>"` | Tạo một task mới |
| `.agent/scripts/kit-task start TASK-NNN` | Bắt đầu làm task (tạo nhánh git riêng) |
| `.agent/scripts/kit-task start TASK-NNN --worktree` | Mở task trong một thư mục git worktree chạy song song |
| `.agent/scripts/kit-task checkpoint "<ghi chú>"` | Lưu mốc tiến độ (tự commit và tag backup) |
| `.agent/scripts/kit-task rollback` | Quay lui về checkpoint trước đó |
| `.agent/scripts/kit-task verify` | Chạy 7 cổng kiểm tra chất lượng bằng máy |
| `.agent/scripts/kit-task finish` | Hoàn tất task, kiểm tra toàn diện và mở Pull Request |
| `.agent/scripts/kit-task merged TASK-NNN` | Đánh dấu task đã được merge và lưu trữ |

### Theo dõi & Báo cáo
| Lệnh | Ý nghĩa |
|---|---|
| `.agent/scripts/kit-board` | Xem bảng Kanban các task ngay trên Terminal |
| `.agent/scripts/kit-board --html` | Mở bảng Kanban trực quan trên trình duyệt Web |
| `.agent/scripts/kit-daily` | Tự động tổng kết báo cáo công việc trong ngày từ git commit |
| `.agent/scripts/kit-run check` | Chạy toàn bộ kiểm tra chất lượng (format, lint, test, arch) |
