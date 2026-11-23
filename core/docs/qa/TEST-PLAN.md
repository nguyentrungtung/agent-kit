# Test plan (toàn dự án)

## Chiến lược
| Tầng | Công cụ | Phạm vi | Chạy khi |
|---|---|---|---|
| Unit | | logic thuần, edge case | mỗi commit (`kit-run test`) |
| Integration | | DB, queue, API ngoài (container) | CI |
| E2E / API | | luồng chính của người dùng | CI trước merge |
| Security | semgrep, trivy, secrets scan | toàn repo | CI |

## Mục tiêu coverage: xem `coverage_min` trong `.agent/project.yaml`
## Dữ liệu test: fixture tối thiểu, không dùng dữ liệu thật / PII thật
## Test case theo task: `docs/qa/TASK-NNN.md`
