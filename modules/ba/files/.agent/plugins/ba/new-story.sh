# kit-new story "<title>" [--uc UC-NN] → docs/ba/stories/US-NN-slug.md (module ba)
title=""; uc=""
while [ $# -gt 0 ]; do case "$1" in --uc) uc="$2"; shift 2 ;; *) title="${title:+$title }$1"; shift ;; esac; done
[ -n "$title" ] || die 'usage: kit-new story "<title>" [--uc UC-NN]'
num="$(next_num docs/ba/stories 'US-' 2)"
render "$TPL/story.md" "$KIT_ROOT/docs/ba/stories/US-$num-$(slug "$title").md" NUM="$num" TITLE="$title" UC="$uc" DATE="$(today)"
