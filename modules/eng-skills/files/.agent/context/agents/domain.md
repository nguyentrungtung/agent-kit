# Domain docs layout (read by mp-domain-modeling, mp-improve-codebase-architecture, mp-tdd)
- Single context: `docs/GLOSSARY.md` + `docs/adr/`.
- Several bounded contexts (modular monolith / services): add `docs/GLOSSARY-MAP.md` pointing to `<module>/GLOSSARY.md`;
  context-specific ADRs may live in `<module>/docs/adr/`, project-wide ones stay in `docs/adr/`.
- Terms in `docs/GLOSSARY.md` are the names used in code, specs (OpenSpec), stories and tests.
