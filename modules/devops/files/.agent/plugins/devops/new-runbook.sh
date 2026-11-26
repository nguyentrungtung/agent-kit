# kit-new runbook "<alert or operation>" → docs/platform/runbooks/<slug>.md (module devops)
title="$*"; [ -n "$title" ] || die 'usage: kit-new runbook "<alert or operation>"'
render "$TPL/runbook.md" "$KIT_ROOT/docs/platform/runbooks/$(slug "$title").md" TITLE="$title" DATE="$(today)"
