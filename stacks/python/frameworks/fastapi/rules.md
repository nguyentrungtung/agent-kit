# FastAPI rules
- Routers per feature (`app/api/orders.py`), thin: Pydantic request/response models → service → response model. Always set `response_model`.
- Dependencies (`Depends`) for DB sessions, auth, settings — never global singletons imported in handlers.
- Async endpoints must not call blocking I/O; use async drivers or `run_in_threadpool`.
- Settings via `pydantic-settings` `BaseSettings`, validated at startup.
- Errors: domain exceptions mapped by exception handlers to RFC 9457 problem responses.
- DB: SQLAlchemy 2.x typed models, Alembic migrations (never edit applied ones).
- Tests: `httpx.AsyncClient`/`TestClient`, dependency overrides for fakes.
