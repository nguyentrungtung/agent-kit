# kit-new usecase "<title>" → docs/ba/use-cases/UC-NN-slug.md (module ba)
title="$*"; [ -n "$title" ] || die 'usage: kit-new usecase "<title>"'
num="$(next_num docs/ba/use-cases 'UC-' 2)"
render "$TPL/usecase.md" "$KIT_ROOT/docs/ba/use-cases/UC-$num-$(slug "$title").md" NUM="$num" TITLE="$title" DATE="$(today)"
