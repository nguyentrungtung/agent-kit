# Logging & observability

- Structured logs (JSON in prod) with stable event names and fields: `event`, `level`, `correlation_id`, ids of business objects.
- Levels: ERROR = needs a human; WARN = degraded but handled; INFO = business events; DEBUG = diagnostics (off in prod).
- Never log secrets, tokens, passwords, full card numbers, or personal data beyond ids. Mask when in doubt.
- Propagate a correlation/trace id across services (W3C Trace Context). Expose health (liveness/readiness) and key metrics (RED: rate, errors, duration).
