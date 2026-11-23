# Domain docs layout (read by mp-domain-modeling, mp-grill-with-docs)
- Single context: `GLOSSARY.md` at the repo root + `docs/adr/`.
- Several bounded contexts (modular monolith / services): add `GLOSSARY-MAP.md` at the root pointing to `<module>/GLOSSARY.md`;
  context-specific ADRs may live in `<module>/docs/adr/`, project-wide ones stay in `docs/adr/`.
- Terms in GLOSSARY.md are the names used in code, specs (OpenSpec), stories and tests.
