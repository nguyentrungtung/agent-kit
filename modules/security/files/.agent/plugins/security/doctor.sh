# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
for t in syft trivy; do command -v "$t" >/dev/null 2>&1 && ok "$t available" || meh "$t not installed — kit-sec-scan uses Docker images"; done
return 0
