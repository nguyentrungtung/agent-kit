# Mandatory filters and gotchas

## Always filter
| Rule | SQL fragment | Why / source |
|---|---|---|
| TODO: only active records | `WHERE is_active = TRUE` | e.g. the source keeps sending rows it no longer reports |

## Gotchas
| Gotcha | What goes wrong | Do instead | Learned from |
|---|---|---|---|
| TODO: string-typed bronze | `'' ` is not NULL; numbers compare as text | cast in silver; test `TRIM(col) = ''` | <incident / doc> |

## Code lists
| Code list | Table / seed | Notes |
|---|---|---|
| TODO | `<seed or table>` | |
