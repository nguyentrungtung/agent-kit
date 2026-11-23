# Release checklist (human-run; agent may prepare)
- [ ] `release/x.y.z` branch from develop; version bumped; CHANGELOG from Conventional Commits
- [ ] CI green on release branch; security scans clean (or accepted risks documented)
- [ ] DB migrations tested forward + backward on a copy of production data
- [ ] Rollback plan written (previous artifact/tag, migration down steps, feature flags)
- [ ] Merge to main with tag `vX.Y.Z`; merge main back into develop
- [ ] Post-release: smoke test, monitor errors/latency for 30 min, daily report entry
