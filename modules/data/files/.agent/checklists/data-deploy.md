# Data deploy checklist — pipelines, models, tables, serving (human-run; the agent prepares and verifies read-only)

Use it for any release that changes how data is loaded, transformed, stored or served, together with `release.md`.
Copy it into the runbook of this deploy (`docs/platform/runbooks/`) and fill in real commands, queries and numbers.
Create the file with `.agent/scripts/kit-new runbook "<release>"` (module `devops`); without that module:
`.agent/scripts/kit-new doc docs/platform/runbooks/<slug>.md "<release>"`.
A step that does not apply gets `n/a — <why>`, never a silent skip. Agents never run it against production.

## 1. Scope — before the deploy day
- [ ] Release identified: tag or commit now on production → tag or commit to deploy; one named person runs it, one decides go / no-go
- [ ] Changed items listed: sources, jobs, schedules, raw/silver/gold tables, serving tables, metrics, config **names** (never values)
- [ ] **How code reaches production is written down.** When a pull is live at once (bind mount, synced DAG folder), **all of §3 Prepare is done before the pull**
- [ ] Each table gets its action: nothing · incremental · backfill (range) · full refresh · in-place migration — with measured duration, disk and memory
- [ ] **Changed metric or business logic:** each metric that will change is listed with the expected direction or size and the owner who agreed; every other metric must stay equal
- [ ] Schema changes reach every consumer in order (e.g. serving DDL together with the new gold column)
- [ ] Rehearsed on a copy or staging with production-like volume, **including the way back**

## 2. Stop and roll back — decided before starting
- [ ] Each trigger has a signal, the command or query that reads it, a **threshold**, and who decides. At least: a step fails or runs past its time budget;
      error-severity data tests fail (staleness caused only by the planned pause does not count); row counts or reconciled totals differ beyond the agreed tolerance; a metric changes that was not listed in §1;
      serving is empty or partly updated, or still stale after the catch-up run
- [ ] Latest time to start the rollback so it still ends inside the window
- [ ] **Point of no return** named: the first step after which going back means restore or forward-fix, and who approves passing it

## 3. Prepare — right before the change
- [ ] Access, disk space, memory and service health checked; the people in §1 are available for the whole window
- [ ] Schedules, sensors and triggers that touch the changed items are paused; running jobs have finished (or were stopped on purpose)
- [ ] Restore points for what will change (previous code ref, table snapshots or backups, serving dump): restore command written,
      restore tested, and they outlive the window (no snapshot expiry or cleanup job removes them meanwhile)
- [ ] **Baseline saved:** row counts, key totals and metric values per period from raw, gold and serving, with the queries that produced them

## 4. Deploy — one step at a time
- [ ] Order written, for example: code → config → migrations of stored data → silver/gold refresh or backfill → serving schema → serving sync
- [ ] Every step has: command, expected result, check, and what to do when it fails. A failed check stops the run
- [ ] Re-running a step is safe, or the runbook says it must not be re-run

## 5. Verify — before schedules are resumed
- [ ] Error-severity data tests pass. Freshness: run the planned catch-up load first (schedules still paused); where only a scheduled run
      can make the data fresh, mark it here and check it in §7 after that run
- [ ] Compared with the baseline: unlisted metrics are equal (within tolerance); listed ones changed as expected; differences are explained, not "fixed" by hand
- [ ] Reconciled with the source for the periods that were reloaded or recalculated (`kit-da`)
- [ ] Consumers see the new data: serving tables, API or dashboard spot-checked

## 6. If a trigger fires — roll back
- [ ] Stop at the current step; schedules **stay paused**. Past the point of no return: restore or forward-fix, decided by the person named in §2
- [ ] Restore in the written order (for example: serving → stored tables → code and config), including steps that only partly ran
- [ ] Compare with the §3 baseline: every changed table, serving table and metric is back. Only then resume the old schedules; record what happened

## 7. Resume and close
- [ ] Schedules resumed one pipeline at a time; the first scheduled run of each is watched to success (and freshness passes, if left open in §5)
- [ ] Consumers told what changed, including metric definitions and restated history
- [ ] Runbook updated with what really happened; living docs, data contracts and catalog match production
- [ ] Restore points, temporary tables and one-off scripts have a removal date and an owner (a one-off script is deleted once run everywhere)
