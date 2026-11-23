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
| FR-01 | WHEN user submits valid credentials, the system SHALL authenticate and issue an active session. | Event-driven | Must | G1 | US-01 |
| FR-02 | IF 5 consecutive failed login attempts occur, THEN the system SHALL lock the account for 15 minutes. | Unwanted | Must | G1 | US-01 |

## Non-functional requirements
| ID | Category | Requirement | Measure |
|---|---|---|---|
| NFR-01 | Performance | | p95 < … ms |
| NFR-02 | Security | | |
| NFR-03 | Availability | | |

## User stories
### US-01 — <title>
**As a** … **I want** … **so that** …
**Acceptance criteria**
- Given … When … Then …

## Business rules
| ID | Rule |
|---|---|
| BR-01 | |

## Traceability
Goal → FR → US → TASK → Test case (cập nhật bởi kit-plan / kit-testcases)
