#!/usr/bin/env python3
"""Vendor selected skills from github.com/mattpocock/skills (MIT) into modules/eng-skills.

Usage (kit maintainers):  python3 -I scripts/vendor-mattpocock.py <path-to-clone-of-mattpocock/skills> <tag>
  1. git clone --depth 1 --branch <tag> https://github.com/mattpocock/skills.git /tmp/mp   (data only, nothing is executed)
  2. run this script, review `git diff modules/eng-skills`, commit.

What it does: copies each selected skill to modules/eng-skills/files/.agent/skills/mp-<name>/, renames the skill and every
cross-reference to the mp- prefix (avoids clashes such as Claude Code's built-in /code-review), applies small agent-kit
patches (marked "agent-kit:"), and writes LICENSE + VENDORED.md into every skill folder.
"""
import os, re, shutil, subprocess, sys

SELECTED = {  # name -> folder inside the upstream repo
    "grilling": "skills/productivity/grilling",
    "grill-with-docs": "skills/engineering/grill-with-docs",
    "domain-modeling": "skills/engineering/domain-modeling",
    "tdd": "skills/engineering/tdd",
    "diagnosing-bugs": "skills/engineering/diagnosing-bugs",
    "codebase-design": "skills/engineering/codebase-design",
    "improve-codebase-architecture": "skills/engineering/improve-codebase-architecture",
    "code-review": "skills/engineering/code-review",
    "pr": "skills/engineering/pr",
    "wizard": "skills/engineering/wizard",
    "retro": "skills/engineering/retro",
    "to-questionnaire": "skills/productivity/to-questionnaire",
    "writing-for-agents": "skills/productivity/writing-for-agents",
}
PREFIX = "mp-"

# agent-kit patches: (skill, exact upstream text, replacement). Missing anchors fail loudly so upgrades are reviewed.
PATCHES = [
    ("code-review",
     "The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.",
     "agent-kit: where specs, tasks and issues live in this repo is described in `docs/agents/issue-tracker.md`."),
    ("code-review",
     "1. Issue references in the commit messages",
     "0. agent-kit: the task file of the current branch (`.agent/tasks/TASK-NNN-*.md`, acceptance criteria) and its OpenSpec change\n"
     "   (`openspec/changes/<change>/` — proposal, specs, design; `change:` in the task front matter).\n"
     "1. Issue references in the commit messages"),
    ("code-review",
     "When `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists, it must be on the list.",
     "When `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists, it must be on the list.\n"
     "agent-kit: `.agent/rules/` (project > stack > core) and `.agent/context/CONVENTIONS.md` are this repo's standards sources."),
]

def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, tag = sys.argv[1], sys.argv[2]
    kit = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dest_root = os.path.join(kit, "modules", "eng-skills", "files", ".agent", "skills")
    commit = subprocess.run(["git", "-C", src, "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    license_text = open(os.path.join(src, "LICENSE")).read()
    names = sorted(SELECTED, key=len, reverse=True)  # longest first: 'grill-with-docs' before 'grilling'
    ref = re.compile(r'(?P<pre>[`"/])(?P<name>' + "|".join(map(re.escape, names)) + r')(?P<post>[`"]|\b(?![-\w]))')

    if os.path.isdir(dest_root):
        for d in os.listdir(dest_root):
            if d.startswith(PREFIX):
                shutil.rmtree(os.path.join(dest_root, d))
    os.makedirs(dest_root, exist_ok=True)

    for name, rel in SELECTED.items():
        s, d = os.path.join(src, rel), os.path.join(dest_root, PREFIX + name)
        shutil.copytree(s, d)
        for root, _, files in os.walk(d):
            for fn in files:
                p = os.path.join(root, fn)
                if not fn.endswith((".md", ".yaml", ".yml", ".sh")):
                    continue
                t = open(p).read()
                t = re.sub(r'^name:\s*' + re.escape(name) + r'\s*$', 'name: ' + PREFIX + name, t, count=1, flags=re.M)
                t = ref.sub(lambda m: m["pre"] + PREFIX + m["name"] + m["post"], t)
                open(p, "w").write(t)
        open(os.path.join(d, "LICENSE"), "w").write(license_text)
        open(os.path.join(d, "VENDORED.md"), "w").write(
            f"Vendored from https://github.com/mattpocock/skills/tree/{tag}/{rel} (commit {commit}), MIT licence (see LICENSE).\n"
            f"Changes by agent-kit: renamed to `{PREFIX}{name}`, cross-references renamed to the `{PREFIX}` prefix,"
            f" lines marked `agent-kit:` added. Update with scripts/vendor-mattpocock.py — do not edit by hand.\n")

    for name, old, new in PATCHES:
        p = os.path.join(dest_root, PREFIX + name, "SKILL.md")
        t = open(p).read()
        old_p = ref.sub(lambda m: m["pre"] + PREFIX + m["name"] + m["post"], old)
        if old_p not in t:
            sys.exit(f"patch anchor not found in {name}: {old[:60]}… — upstream changed, review the patch")
        open(p, "w").write(t.replace(old_p, new, 1))
    print(f"vendored {len(SELECTED)} skills from {tag} ({commit}) into {os.path.relpath(dest_root, kit)}")

if __name__ == "__main__":
    main()
