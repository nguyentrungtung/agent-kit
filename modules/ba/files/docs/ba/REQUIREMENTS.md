# Requirements

## Functional requirements (EARS Syntax)
<!-- 
Mọi yêu cầu chức năng viết theo chuẩn EARS (Easy Approach to Requirements Syntax) để tránh mơ hồ:
- Event-driven: WHEN <sự kiện>, the system SHALL <hành động>.
- State-driven: WHILE <trạng thái>, the system SHALL <hành động>.
- Unwanted: IF <lỗi/ngoại lệ>, THEN the system SHALL <xử lý an toàn>.
- Optional: WHERE <tùy chọn bật>, the system SHALL <hành động>.
-->
| ID | Requirement (EARS) | Pattern | Priority (MoSCoW) | Goal | Stories |
|---|---|---|---|---|---|
| FR-01 | WHEN `<trigger>`, the system SHALL `<response>`. | Event-driven | Must | G1 | `<US-NN>` |
| FR-02 | IF `<unwanted condition>`, THEN the system SHALL `<safe response>`. | Unwanted | Must | G1 | `<US-NN>` |

## Non-functional requirements
| ID | Category | Requirement | Measure |
|---|---|---|---|
| NFR-01 | Performance | `<requirement>` | `<p95 < … ms>` |
| NFR-02 | Security | `<requirement>` | `<measure>` |
| NFR-03 | Availability | `<requirement>` | `<measure>` |

## User stories
### US-NN — `<title>`
**As a** … **I want** … **so that** …
**Acceptance criteria**
- Given … When … Then …

## Business rules
| ID | Rule |
|---|---|
| BR-01 | `<rule>` |

## Traceability
Goal → FR → US → TASK → Test case (cập nhật bởi kit-plan / kit-testcases)
