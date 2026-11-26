#!/usr/bin/env bash
# PreToolUse(Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob) guardrail.
#  - secrets (.env, keys, credentials): never read or written by the agent
#  - guardrail files (hooks, git hooks, Claude settings, .git/): read-only for the agent
#  - CI workflows: editing needs human confirmation
source "$(dirname "$0")/_hooklib.sh"

tool="$(json_get tool_name)"
p="$(json_get tool_input.file_path)"
[ -z "$p" ] && p="$(json_get tool_input.notebook_path)"
[ -z "$p" ] && p="$(json_get tool_input.path)"
[ -z "$p" ] && exit 0
rel="$(P="$p" BASE="$PROJECT_DIR" perl -MCwd=realpath -e '
  my $base = realpath($ENV{BASE}) // $ENV{BASE};
  $base =~ s{/+$}{};
  my $p = $ENV{P};
  $p = "$base/$p" unless $p =~ m{^/};
  my @seg = split m{/+}, $p;
  my @acc;
  my $hops = 0;
  while (@seg) {
    my $s = shift @seg;
    next if $s eq "" || $s eq ".";
    if ($s eq "..") { pop @acc if @acc; next; }
    push @acc, $s;
    my $cur = "/" . join("/", @acc);
    if (-l $cur) {
      last if ++$hops > 40;
      my $t = readlink($cur);
      if (defined $t) {
        pop @acc;
        @acc = () if $t =~ m{^/};
        unshift @seg, split(m{/+}, $t);
        next;
      }
    }
    if (-e $cur) {
      my $r = realpath($cur);
      if (defined $r) { $r =~ s{^/}{}; @acc = ($r eq "" ? () : split(m{/}, $r)); }
    }
  }
  my $abs = "/" . join("/", @acc);
  if ($abs eq $base) { print "."; }
  elsif ($abs =~ m{^\Q$base\E/(.*)$}i && $^O eq "darwin") { print $1; }
  elsif ($abs =~ m{^\Q$base\E/(.*)$}) { print $1; }
  else { print $abs; }
')"

secret='(?i)(^|/)\.env(\.(?!example$|sample$|template$|dist$)[^/]+)?$|\.(pem|key|p12|pfx|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa|dsa)$|(^|/)\.aws/credentials$|(^|/)\.ssh(?:/|$)|(^|/)credentials(\.json)?$|service-account[^/]*\.json$|(^|/)secrets?(?:/|$)|\.tfstate(\.backup)?$|(^|/)\.(npmrc|pypirc|netrc)$'
if re "$secret" "$rel"; then
  deny "access to secret file '$rel'" "use .env.example for variable names; values are set by a human"
fi

case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit)
    if re '(?i)^(\.agent/hooks(?:/|$)|\.agent/githooks(?:/|$)|\.githooks(?:/|$)|\.git(?:/|$)|\.claude/settings(\.local)?\.json$)' "$rel"; then
      deny "guardrail file '$rel' is read-only for the agent" "describe the change; a human applies it"
    fi
    if re '(?i)^\.github/workflows/' "$rel"; then
      ask "editing CI workflow '$rel' (can weaken quality gates)"
    fi
    if re '(?i)(^|/)(\.php-cs-fixer(\.dist)?\.php|phpstan\.neon(\.dist)?|deptrac\.ya?ml|pint\.json|eslint\.config\.[cm]?[jt]s|\.eslintrc[^/]*|\.prettierrc[^/]*|\.dependency-cruiser\.[cm]?js|ruff\.toml|mypy\.ini|\.importlinter|\.golangci\.ya?ml|rustfmt\.toml|clippy\.toml|deny\.toml|\.editorconfig|Directory\.Build\.props|checkstyle[^/]*\.xml)$' "$rel"; then
      ask "editing quality-tool config '$rel' (must not weaken rules — needs an ADR if relaxing)"
    fi
    if re '(?i)^openspec/(config\.ya?ml|schemas/)' "$rel"; then
      ask "editing the OpenSpec workflow/config '$rel' (team-wide workflow change)"
    fi
    if re '(?i)^openspec/specs/' "$rel"; then
      ask "editing a living spec directly — behaviour changes go through an OpenSpec change (openspec/changes/<name>/specs/); direct edits only for Purpose/typos"
    fi
    if re '(?i)^(infra|deploy|k8s|helm|terraform)/' "$rel"; then
      ask "editing infrastructure/deployment code '$rel' (a human will review and apply it)"
    fi
    if re '(?i)^\.agent/rules/' "$rel"; then
      ask "editing project rules '$rel'"
    fi
    if re '(?i)^\.agent/project\.yaml$' "$rel"; then
      ask "editing .agent/project.yaml changes lint/test commands and protected branches"
    fi
    ;;
esac
exit 0
