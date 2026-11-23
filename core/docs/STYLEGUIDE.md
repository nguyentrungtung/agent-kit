# Quy chuẩn Viết Tài liệu Markdown (Documentation Style Guide)

Tài liệu này định nghĩa tiêu chuẩn viết tài liệu kỹ thuật bằng Markdown trong toàn bộ dự án, áp dụng cho cả lập trình viên và AI coding agents. Tiêu chuẩn này kết hợp giữa **Kiến trúc tài liệu Diátaxis (chuẩn quốc tế)** và **Google / GitHub Markdown Style Guide**.

---

## 1. Kiến trúc tài liệu theo Khung Diátaxis (The Diataxis Framework)

Mọi tài liệu trong dự án bắt buộc phải thuộc một trong 4 góc phần tư của Diátaxis. **Tuyệt đối không trộn lẫn mục đích** của các loại tài liệu trên cùng một trang:

```text
               HỌC TẬP (Learning)
                     ▲
                     │
       TUTORIALS     │    EXPLANATION
     (Cầm tay chỉ việc)│  (Kiến trúc & Lý do)
                     │
THỰC HÀNH ───────────┼─────────── LÝ THUYẾT / TRA CỨU
(Practical)          │            (Theoretical / Reference)
                     │
     HOW-TO GUIDES   │    REFERENCE
   (Giải quyết tác vụ)│  (Tra cứu thông số)
                     │
                     ▼
               CÔNG VIỆC (Work)
```

| Loại tài liệu | Mục tiêu | Đối tượng & Giọng văn | Ví dụ trong dự án |
|---|---|---|---|
| **1. Tutorials** | Hướng dẫn người mới đi từng bước để đạt được thành công đầu tiên (Hello World). | Dẫn dắt, tuần tự, chỉ có 1 con đường duy nhất, không rẽ nhánh. | [USER_GUIDE.md](../../USER_GUIDE.md) |
| **2. How-to Guides** | Hướng dẫn giải quyết một vấn đề cụ thể trong công việc thực tế. | Giả định người đọc đã có chuyên môn; ngắn gọn, tập trung vào kết quả. | `docs/platform/runbooks/`, hướng dẫn rollback, hướng dẫn thêm stack mới. |
| **3. Reference** | Tra cứu thông số kỹ thuật, API, CLI commands, cấu hình. | Khô khan, chính xác tuyệt đối, cấu trúc dạng bảng/danh sách, không giải thích dài dòng. | `docs/api/openapi.yaml`, [README.md](../../README.md) bảng lệnh CLI. |
| **4. Explanation** | Giải thích bức tranh tổng thể, kiến trúc hệ thống, lý do "Tại sao làm thế này?". | Phân tích, so sánh các phương án (trade-offs), sơ đồ tương tác. | `docs/architecture/SOLUTION.md`, `docs/adr/` (Quyết định kiến trúc). |

---

## 2. Quy chuẩn Định dạng Markdown (Markdown Formatting Rules)

### 2.1. Cấu trúc Tiêu đề (Heading Hierarchy)
* **Chỉ một H1 (`#`) duy nhất** ở đầu file làm tiêu đề tài liệu.
* **Không nhảy cấp tiêu đề:** Từ `# H1` $\to$ `## H2` $\to$ `### H3`. Tuyệt đối không nhảy từ `# H1` thẳng xuống `### H3`.
* **Viết hoa chữ cái đầu và súc tích:** Tiêu đề mục cần ngắn gọn, rõ nghĩa.

### 2.2. Metadata Front Matter (Bắt buộc cho tài liệu sống)
Mọi file tài liệu trong `docs/` (trừ tài liệu tạm thời) bắt buộc có YAML front matter ở đầu:
```yaml
---
title: Tên tài liệu
category: tutorial | how-to | reference | explanation
status: draft | approved | deprecated
owner: TechLead / Team / Tên tác giả
updated: YYYY-MM-DD
---
```

### 2.3. Khối mã nguồn (Code Fences & Syntax Highlighting)
* **Luôn khai báo ngôn ngữ rõ ràng** sau 3 dấu backticks. Không bao giờ để ` ``` ` trơ trọi:
  ```markdown
  ```bash
  git status
  ```
  ```json
  { "name": "agent-kit" }
  ```
  ```typescript
  export const add = (a: number, b: number): number => a + b;
  ```
  ```

### 2.4. Khối thông báo & Cảnh báo (GitHub-style Alerts)
Sử dụng chuẩn GitHub Flavored Markdown Alerts để nhấn mạnh thông tin quan trọng. Không lồng ghép nhiều alert liên tiếp:
```markdown
> [!NOTE]
> Thông tin bối cảnh, chi tiết kỹ thuật hoặc giải thích bổ sung.

> [!TIP]
> Lời khuyên tối ưu hiệu năng, mẹo làm việc nhanh hoặc thực hành tốt nhất.

> [!IMPORTANT]
> Yêu cầu bắt buộc, bước cốt lõi hoặc thông tin không được phép bỏ qua.

> [!WARNING]
> Cảnh báo rủi ro, lỗi thường gặp hoặc các thay đổi có thể gây phá vỡ tương thích.

> [!CAUTION]
> Cảnh báo nguy hiểm cao: hành động có thể gây mất dữ liệu hoặc rò rỉ bảo mật.
```

### 2.5. Sơ đồ Trực quan (Mermaid & PlantUML)
* Mọi sơ đồ phải được kiểm tra cú pháp trước khi commit bằng lệnh `.agent/scripts/kit-run docs`.
* Nhãn của các node có chứa ký tự đặc biệt hoặc dấu cách phải được đặt trong dấu ngoặc kép:
  ```markdown
  ```mermaid
  flowchart LR
    A["Khách hàng (Client)"] --> B["API Gateway"]
    B --> C["Dịch vụ Xác thực (Auth Service)"]
  ```
  ```

### 2.6. Bảng biểu (Tables)
* Bảng phải có dòng tiêu đề rõ ràng và dòng phân cách `|---|---|`.
* Căn chỉnh cột hợp lý:
  - Căn trái (`:---`): Cho văn bản thông thường, mô tả.
  - Căn giữa (`:---:`): Cho ID, Trạng thái (Status), Nhãn ngắn.
  - Căn phải (`---:`): Cho số lượng, giá tiền, phần trăm.

### 2.7. Liên kết (Links)
* **Chỉ sử dụng Relative Path (Đường dẫn tương đối)** khi trỏ tới các file trong repo:
  * ✅ Đúng: `[Kiến trúc hệ thống](../architecture/SOLUTION.md)`
  * ❌ Sai: `[Kiến trúc](/Users/tungnt/Desktop/.../SOLUTION.md)` (Đường dẫn tuyệt đối sẽ hỏng trên máy người khác).

---

## 3. Vòng đời Tài liệu & Vệ sinh Dự án (Documentation Hygiene)

1. **Một nguồn sự thật duy nhất (Single Source of Truth):** Không sao chép lặp lại cùng một nội dung ở 2 file khác nhau. Hãy dùng liên kết dẫn chiếu.
2. **Quy tắc Living Docs:** Một Pull Request thay đổi hành vi hoặc kiến trúc của code mà không cập nhật tài liệu tương ứng là **chưa hoàn thành (Chưa đạt Definition of Done)**.
3. **Thu hồi tài liệu cũ:** Khi một tài liệu hoặc tính năng không còn sử dụng, đổi `status: deprecated` và ghi rõ tài liệu mới thay thế ở đầu trang.
