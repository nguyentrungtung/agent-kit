# Laravel rules

Formatting: **Pint** with the `laravel` preset (Laravel's own PSR-12/PER-based style). Types: **Larastan**.

- Controllers are thin: validate (Form Request) → call an Action/Service → return a Resource/Response. No queries or business rules in controllers.
- Validation lives in `FormRequest` classes; authorization in Policies/Gates (`$this->authorize()`), never ad-hoc `if ($user->role == ...)`.
- Business logic in single-purpose **Actions** (`app/Actions/PlaceOrder.php`) or Services; reusable from HTTP, jobs and commands.
- Eloquent: eager-load relations (`with()`) — no N+1 (enable `Model::preventLazyLoading()` outside production).
  Mass assignment through `$fillable`, never `$guarded = []`. Casts for enums/dates/JSON.
- API output through `JsonResource`, never raw models (hides columns, stable contract).
- DB changes only via migrations; never edit a migration that has run on a shared environment — add a new one.
- Config through `config()` only; `env()` is allowed **only inside `config/*.php`** (breaks with config cache otherwise).
- Long work → queued Jobs (idempotent, with `tries`/`backoff`). Side effects after commit: `afterCommit()`.
- Routes named (`->name('orders.store')`) and grouped by middleware; use route model binding.
- Tests: Pest/PHPUnit Feature tests with `RefreshDatabase`; factories for data; `Http::fake()`, `Queue::fake()`, `Mail::fake()` for edges.
