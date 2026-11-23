# Django rules
- One Django app per bounded context; business logic in services/domain modules, not in views or signals.
- Fat models only for invariants of that model; avoid hidden side effects in `save()` and signals.
- Queries: `select_related`/`prefetch_related` to avoid N+1; no raw SQL string formatting.
- Forms/DRF serializers validate all input; DRF permissions on every view.
- Settings split by env, secrets from env vars; `DEBUG=False` + `ALLOWED_HOSTS` in prod.
- Migrations committed, reviewed, never edited after being applied on shared envs.
- Tests: pytest-django, factories (factory_boy), `@pytest.mark.django_db`.
