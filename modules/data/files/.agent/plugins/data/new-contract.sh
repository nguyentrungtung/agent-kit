# kit-new contract "<dataset>" → docs/data/contracts/<slug>.md (module data)
title="$*"; [ -n "$title" ] || die 'usage: kit-new contract "<dataset>"'
render "$TPL/data-contract.md" "$KIT_ROOT/docs/data/contracts/$(slug "$title").md" TITLE="$title" DATE="$(today)"
