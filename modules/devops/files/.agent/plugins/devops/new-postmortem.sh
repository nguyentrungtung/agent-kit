# kit-new postmortem "<incident title>" → docs/platform/incidents/<date>-<slug>.md (module devops)
title="$*"; [ -n "$title" ] || die 'usage: kit-new postmortem "<incident title>"'
render "$TPL/postmortem.md" "$KIT_ROOT/docs/platform/incidents/$(today)-$(slug "$title").md" TITLE="$title" DATE="$(today)"
