#!/usr/bin/env bash
# PreToolUse(Bash) guardrail. Blocks: bypassing git hooks, pushing/forcing protected branches,
# destroying work outside kit-task, reading/committing secrets, pipe-to-shell, and asks before deploys.
source "$(dirname "$0")/_hooklib.sh"

cmd="$(json_get tool_input.command)"
[ -z "$cmd" ] && exit 0
c="$(printf '%s' "$cmd" | tr '\n' ' ')"
set -f   # no glob expansion when tokenizing the command

# Commands routed through this repo's kit scripts are trusted (only single commands with no unquoted metacharacters/redirections).
is_trusted_kit_cmd() {
  CMD="$cmd" PDIR="$PROJECT_DIR" perl -MCwd=realpath -e '
    my $c = $ENV{CMD};
    exit 1 if $c =~ /[\r\n`]/ || $c =~ /\$\(/;
    # Character-level POSIX/Bash quote stripper (handles '\''...'\'', "...", $'\''...'\'', outside-quote \x)
    my ($u, $q) = ("", "");
    my $len = length($c);
    for (my $i = 0; $i < $len; $i++) {
      my $ch = substr($c, $i, 1);
      if ($q eq "") {
        if (substr($c, $i, 2) eq "\$'\''") { $q = "\$'\''"; $u .= " "; $i++; }
        elsif ($ch eq "'\''" || $ch eq "\"") { $q = $ch; $u .= " "; }
        elsif ($ch eq "\\") { $u .= "  "; $i++ if $i + 1 < $len; }
        else { $u .= $ch; }
      } elsif ($q eq "'\''") {
        $q = "" if $ch eq "'\''";
      } else {
        if ($ch eq "\\") { $i++ if $i + 1 < $len; }
        elsif ($ch eq ($q eq "\"" ? "\"" : "'\''")) { $q = ""; }
      }
    }
    exit 1 if $q ne "";
    exit 1 if $u =~ /[;&|<>(){}]/;
    $u =~ s/^\s+//;
    my ($first) = ($u =~ m{^(\S+)});
    exit 1 unless defined $first && $first =~ m{^((?:.*/)?\.agent/scripts)/kit-[a-z-]+$};
    my $dir = $1;
    if ($dir ne ".agent/scripts") {
      my $pdir = realpath($ENV{PDIR}) // $ENV{PDIR};
      my $target = ($dir =~ m{^/}) ? $dir : "$pdir/$dir";
      my $r = realpath($target);
      my $expected = realpath("$pdir/.agent/scripts");
      exit 1 unless defined($r) && defined($expected) && ($r eq $expected || ($^O eq "darwin" && lc($r) eq lc($expected)));
    }
    exit 0;
  '
}
is_trusted_kit_cmd && exit 0

# Unquoted view of $c (character-level state machine so \" / \'\'' outside quotes never mask shell ops)
unquoted_c="$(C="$c" perl -e '
  my $s = $ENV{C};
  my ($u, $q, $len) = ("", "", length($s));
  for (my $i = 0; $i < $len; $i++) {
    my $ch = substr($s, $i, 1);
    if ($q eq "") {
      if (substr($s, $i, 2) eq "\$'\''") { $q = "\$'\''"; $u .= " "; $i++; }
      elsif ($ch eq "'\''" || $ch eq "\"") { $q = $ch; $u .= " "; }
      elsif ($ch eq "\\") { $u .= "  "; $i++ if $i + 1 < $len; }
      else { $u .= $ch; }
    } elsif ($q eq "'\''") {
      $q = "" if $ch eq "'\''";
    } else {
      if ($ch eq "\\") { $i++ if $i + 1 < $len; }
      elsif ($ch eq ($q eq "\"" ? "\"" : "'\''")) { $q = ""; }
    }
  }
  print $u;
')"

has_guard_redir() {
  C="$c" perl -e '
    my $s = $ENV{C};
    my ($q, $len) = ("", length($s));
    my ($cur, $has, $expect) = ("", 0, 0);
    my $guard = qr{(?i)(\.agent/hooks|\.agent/githooks|\.githooks|\.claude/settings[^ ]*\.json)};
    my $norm = sub {
      my $w = shift;
      1 while $w =~ s{/(?:\./)+}{/}g;
      $w =~ s{^\./}{};
      1 while $w =~ s{([^/]+/\.\./)}{ $1 eq "../" ? "../" : "" }eg;
      return $w;
    };
    my $flush = sub {
      if ($has) {
        if ($expect) { exit 0 if $norm->($cur) =~ $guard; $expect = 0; }
        $cur = ""; $has = 0;
      }
    };
    for (my $i = 0; $i < $len; $i++) {
      my $ch = substr($s, $i, 1);
      if ($q eq "") {
        if (substr($s, $i, 2) eq "\$'\''") { $q = "\$'\''"; $has = 1; $i++; }
        elsif ($ch eq "'\''" || $ch eq "\"") { $q = $ch; $has = 1; }
        elsif ($ch eq "\\") {
          if ($i + 1 < $len) { $cur .= substr($s, ++$i, 1); }
          $has = 1;
        } elsif ($ch =~ /\s|[;|&]/) {
          $flush->();
          $expect = 0 if $ch =~ /[;|&]/;
        } elsif ($ch eq ">") {
          $flush->();
          $i++ while $i + 1 < $len && substr($s, $i + 1, 1) =~ /[>|&]/;
          $expect = 1;
        } else {
          $cur .= $ch; $has = 1;
        }
      } elsif ($q eq "'\''") {
        if ($ch eq "'\''") { $q = ""; } else { $cur .= $ch; }
      } else {
        if ($ch eq "\\") { $cur .= substr($s, ++$i, 1) if $i + 1 < $len; }
        elsif ($ch eq ($q eq "\"" ? "\"" : "'\''")) { $q = ""; }
        else { $cur .= $ch; }
      }
    }
    $flush->();
    exit 1;
  '
}

# 1) Never bypass hooks / guardrails
re '--no-verify\b' "$c" && deny "--no-verify bypasses quality/secret hooks" "fix the reported problem, then commit normally"
re 'core\.hooksPath' "$c" && deny "changing core.hooksPath disables git hooks"
re '\b(HUSKY|KIT_SKIP[A-Z_]*|KIT_ALLOW[A-Z_]*|KIT_RELEASE_PREP|SKIP)=' "$c" && deny "skipping hooks via env vars is not allowed"
guard='(?i)(\.agent/hooks|\.agent/githooks|\.githooks|\.claude/settings[^ ]*\.json)'
if re "$guard" "$c" && { re '\b(rm|mv|cp|chmod|truncate|ln|tee|install)\b|\bsed\s+(-\S+\s+)*-i' "$unquoted_c" || has_guard_redir; }; then
  deny "guardrail files can only be changed by a human"
fi

# 2) Protected branches: no push, no force, no history rewrite (wrapper/subshell/global-flag aware git parser)
git_info="$(CMD="$cmd" perl -e '
  my %needs_arg = map { $_ => 1 } qw(-c -C --git-dir --work-tree --namespace --super-prefix --config-env --exec-path);
  sub scan_shell {
    my ($s, $depth) = @_;
    return if $depth > 5;
    my (@cmds, $cur, $q) = ();
    $cur = ""; $q = "";
    my $len = length($s);
    for (my $i = 0; $i < $len; $i++) {
      my $ch = substr($s, $i, 1);
      if ($q eq "" || $q eq "\"") {
        if (substr($s, $i, 2) eq "\$(") {
          my ($j, $pd, $iq, $sub) = ($i + 2, 1, "", "");
          while ($j < $len && $pd > 0) {
            my $c2 = substr($s, $j, 1);
            if ($iq eq "") {
              if (substr($s, $j, 2) eq "\$'\''") { $iq = "\$'\''"; $sub .= "\$'\''"; $j += 2; next; }
              elsif ($c2 eq "'\''" || $c2 eq "\"") { $iq = $c2; $sub .= $c2; }
              elsif ($c2 eq "\\") { $sub .= substr($s, $j, 2); $j += 2; next; }
              elsif ($c2 eq "(") { $pd++; $sub .= $c2; }
              elsif ($c2 eq ")") { $pd--; last if $pd == 0; $sub .= $c2; }
              else { $sub .= $c2; }
            } elsif ($iq eq "'\''") {
              $iq = "" if $c2 eq "'\''";
              $sub .= $c2;
            } else {
              if ($c2 eq "\\") { $sub .= substr($s, $j, 2); $j += 2; next; }
              elsif ($c2 eq ($iq eq "\"" ? "\"" : "'\''")) { $iq = ""; }
              $sub .= $c2;
            }
            $j++;
          }
          scan_shell($sub, $depth + 1) if $sub =~ /\S/;
          $cur .= " __SUB__ ";
          $i = $j;
          next;
        }
        if ($ch eq "`") {
          my ($j, $sub) = ($i + 1, "");
          while ($j < $len) {
            my $c2 = substr($s, $j, 1);
            if ($c2 eq "\\") { $sub .= substr($s, $j, 2); $j += 2; next; }
            last if $c2 eq "`";
            $sub .= $c2; $j++;
          }
          scan_shell($sub, $depth + 1) if $sub =~ /\S/;
          $cur .= " __SUB__ ";
          $i = $j;
          next;
        }
      }
      if ($q eq "") {
        if (substr($s, $i, 2) eq "\$'\''") { $q = "\$'\''"; $cur .= "\$'\''"; $i++; }
        elsif ($ch eq "'\''" || $ch eq "\"") { $q = $ch; $cur .= $ch; }
        elsif ($ch eq "\\") { $cur .= substr($s, $i, 2); $i++ if $i + 1 < $len; }
        elsif ($ch =~ /[\r\n;|&()]/) { push @cmds, $cur if $cur =~ /\S/; $cur = ""; }
        elsif ($ch eq "#" && ($cur eq "" || $cur =~ /\s$/)) { $i++ while $i + 1 < $len && substr($s, $i + 1, 1) ne "\n"; }
        else { $cur .= $ch; }
      } elsif ($q eq "'\''") {
        $cur .= $ch; $q = "" if $ch eq "'\''";
      } else {
        $cur .= $ch;
        if ($ch eq "\\") { if ($i + 1 < $len) { $cur .= substr($s, ++$i, 1); } }
        elsif ($ch eq ($q eq "\"" ? "\"" : "'\''")) { $q = ""; }
      }
    }
    push @cmds, $cur if $cur =~ /\S/;

    LINE: for my $line (@cmds) {
      my (@toks, $t, $in, $tq) = ();
      $t = ""; $in = 0; $tq = "";
      my $llen = length($line);
      for (my $i = 0; $i < $llen; $i++) {
        my $ch = substr($line, $i, 1);
        if ($tq eq "") {
          if ($ch =~ /\s/) { push @toks, $t if $in; $t = ""; $in = 0; }
          elsif (substr($line, $i, 2) eq "\$'\''") { $tq = "\$'\''"; $in = 1; $i++; }
          elsif ($ch eq "'\''" || $ch eq "\"") { $tq = $ch; $in = 1; }
          elsif ($ch eq "\\") { $t .= substr($line, ++$i, 1) if $i + 1 < $llen; $in = 1; }
          else { $t .= $ch; $in = 1; }
        } elsif ($tq eq "'\''") {
          if ($ch eq "'\''") { $tq = ""; } else { $t .= $ch; }
        } else {
          if ($ch eq "\\") { $t .= substr($line, ++$i, 1) if $i + 1 < $llen; }
          elsif ($ch eq ($tq eq "\"" ? "\"" : "'\''")) { $tq = ""; }
          else { $t .= $ch; }
        }
      }
      push @toks, $t if $in;
      my ($wrap_dir, $env_git_dir) = ("", "");
      while (@toks) {
        if ($toks[0] =~ /^(?:!|\{|\}|then|do|else|elif|nohup)$/) { shift @toks; next; }
        if ($toks[0] eq "time") { shift @toks; shift @toks if @toks && $toks[0] eq "-p"; next; }
        if ($toks[0] =~ /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/) {
          $env_git_dir = $2 if $1 eq "GIT_DIR";
          shift @toks; next;
        }
        if ($toks[0] =~ m{^(?:.*/)?env$}) {
          shift @toks;
          while (@toks) {
            if ($toks[0] eq "--") { shift @toks; last; }
            if ($toks[0] eq "-C" && @toks > 1) {
              shift @toks; my $d = shift @toks;
              $wrap_dir = ($d =~ m{^/} || $wrap_dir eq "") ? $d : "$wrap_dir/$d";
              next;
            }
            if ($toks[0] =~ /^--chdir=(.+)$/) {
              my $d = $1; shift @toks;
              $wrap_dir = ($d =~ m{^/} || $wrap_dir eq "") ? $d : "$wrap_dir/$d";
              next;
            }
            if ($toks[0] eq "-u" && @toks > 1) { splice @toks, 0, 2; next; }
            if ($toks[0] =~ /^-/) { shift @toks; next; }
            if ($toks[0] =~ /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/) {
              $env_git_dir = $2 if $1 eq "GIT_DIR";
              shift @toks; next;
            }
            last;
          }
          next;
        }
        if ($toks[0] eq "command") {
          shift @toks;
          while (@toks && $toks[0] =~ /^-/) {
            my $f = shift @toks;
            next LINE if $f =~ /[vV]/;
            last if $f eq "--";
          }
          next;
        }
        if ($toks[0] eq "exec") {
          shift @toks;
          while (@toks && $toks[0] =~ /^-/) {
            my $f = shift @toks;
            shift @toks if $f eq "-a" && @toks;
            last if $f eq "--";
          }
          next;
        }
        if ($toks[0] eq "nice") {
          shift @toks;
          while (@toks && $toks[0] =~ /^-/) {
            my $f = shift @toks;
            shift @toks if $f eq "-n" && @toks;
            last if $f eq "--";
          }
          next;
        }
        if ($toks[0] eq "timeout") {
          shift @toks;
          while (@toks && $toks[0] =~ /^-/) {
            my $f = shift @toks;
            shift @toks if ($f eq "-s" || $f eq "-k") && @toks;
            last if $f eq "--";
          }
          shift @toks if @toks; # duration
          next;
        }
        if ($toks[0] eq "eval") {
          shift @toks;
          scan_shell(join(" ", @toks), $depth + 1) if @toks;
          next LINE;
        }
        if ($toks[0] =~ m{^(?:.*/)?(?:ba|z|da|k|a)?sh$}) {
          shift @toks;
          while (@toks) {
            my $f = shift @toks;
            if ($f =~ /^-[A-Za-z]*c$/ && @toks) { scan_shell($toks[0], $depth + 1); next LINE; }
            last unless $f =~ /^-/;
          }
          next LINE;
        }
        last;
      }
      next unless @toks && ($toks[0] eq "git" || $toks[0] =~ m{/git$});
      shift @toks;
      my $gdir = $wrap_dir;
      my $git_dir = $env_git_dir;
      while (@toks && $toks[0] =~ /^-/) {
        my $fl = shift @toks;
        last if $fl eq "--";
        my $add_c = "";
        if ($fl eq "-C" && @toks) { $add_c = shift @toks; }
        elsif ($fl =~ /^-C(.+)$/) { $add_c = $1; }
        elsif ($fl eq "--git-dir" && @toks) { $git_dir = shift @toks; }
        elsif ($fl =~ /^--git-dir=(.+)$/) { $git_dir = $1; }
        elsif ($needs_arg{$fl} && @toks) { shift @toks; }
        if ($add_c ne "") {
          $gdir = ($add_c =~ m{^/} || $gdir eq "") ? $add_c : "$gdir/$add_c";
        }
      }
      next unless @toks;
      my $sub = shift @toks;
      print "$sub\x1f$gdir\x1f$git_dir\x1f" . join(" ", @toks) . "\n";
    }
  }
  scan_shell($ENV{CMD}, 0);
')"

while IFS=$'\x1f' read -r gsub gdir gitdir gargs; do
  [ -n "${gsub:-}" ] || continue
  target_dir="$PROJECT_DIR"
  if [ -n "$gdir" ]; then
    case "$gdir" in /*) target_dir="$gdir" ;; *) target_dir="$PROJECT_DIR/$gdir" ;; esac
  fi
  git_cmd=(git -C "$target_dir")
  [ -n "${gitdir:-}" ] && git_cmd+=(--git-dir="$gitdir")
  case "$gsub" in
    push)
      re '(^|\s)(-f|--force)(\s|$)|(^|\s)\+\S+' "$gargs" && deny "force push is not allowed" "use: .agent/scripts/kit-task rollback (keeps a backup branch)"
      re '(^|\s)--delete(\s|$)|(^|\s):\S+' "$gargs" && deny "deleting remote refs needs a human"
      branch="$("${git_cmd[@]}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
      has_refspec=0
      for tok in $gargs; do
        case "$tok" in -*) continue ;; esac
        # second+ non-flag arg is a refspec; single non-flag arg might be remote name
        if [ $has_refspec -eq 0 ]; then has_refspec=1; fi
        t="${tok#*:}"; t="${t#refs/heads/}"
        if [[ "$t" =~ $PROTECTED_RE ]]; then deny "pushing to protected branch '$t'" "open a PR: .agent/scripts/kit-task finish"; fi
      done
      if [[ "$branch" =~ $PROTECTED_RE ]] && re '^(\s*-\S+)*(\s+[A-Za-z0-9_.-]+)?\s*$' "$gargs"; then
        deny "current branch '$branch' is protected" "start a task: .agent/scripts/kit-task start TASK-NNN"
      fi ;;
    commit|merge|rebase|cherry-pick|revert)
      branch="$("${git_cmd[@]}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
      [[ "$branch" =~ $PROTECTED_RE ]] && deny "do not commit/merge directly on protected branch '$branch'" "start a task branch: .agent/scripts/kit-task start TASK-NNN" ;;
    reset|clean|checkout|restore|stash|tag|branch|update-ref|reflog|filter-branch|filter-repo)
      re '^(reset\s+.*--hard|clean\s+.*-\S*f|checkout\s+--\s+\.|restore\s+(--\S+\s+)*\.(\s|$)|stash\s+(drop|clear)|tag\s+-d\s+kit/|branch\s+-D|update-ref\s+-d|reflog\s+expire|filter-branch|filter-repo)' "$gsub $gargs" \
        && deny "this git command destroys work without a backup" "use: .agent/scripts/kit-task rollback [--to base|cp-N]  or  kit-task abandon" ;;
  esac
done <<< "$git_info"

# 3) Secrets: never read, print, copy or stage env/key files
envfile='(^|[\s/"'"'"'=])\.env(\.(?!example|sample|template|dist)[A-Za-z0-9_-]+)?(?=$|[\s"'"'"';|&)])'
keyfile='\.(pem|key|p12|pfx|jks|keystore)\b|\bid_(rsa|ed25519|ecdsa|dsa)\b|\.aws/credentials|\.ssh/|\.kube/config|\.npmrc|\.pypirc|\.netrc|\.docker/config\.json'
if re "$envfile" "$c" || re "$keyfile" "$c"; then
  re '\bgit\s+(rm\s+--cached|check-ignore)\b' "$c" || \
  deny "commands touching secret files (.env, keys, credentials) are blocked" "reference variable NAMES from .env.example; ask the human to set values"
fi
re '^\s*(printenv|env|set|export\s+-p|declare\s+-x)\s*($|[|;&>])' "$c" && deny "dumping environment variables can leak secrets"
re '(?i)echo\s+.*\$\{?[A-Z_]*(SECRET|TOKEN|PASSWORD|PASSWD|API_?KEY|PRIVATE)' "$c" && deny "printing secret env vars is not allowed"
re '\bgit\s+add\s+(-\S*f\b|--force)' "$c" && deny "git add --force can stage ignored secret files"

# 4) Dangerous shell
re '\b(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z|da)?sh\b' "$c" && deny "piping downloads into a shell is not allowed"
re '\brm\s+(-\S*\s+)*-\S*[rR]\S*\s+(-\S+\s+)*("|'"'"')?(/|~|\$HOME|\.|\.\.|\*|\.git|\.agent)("|'"'"')?(\s|/?$|/\*)' "$c" \
  && deny "recursive delete of a critical path" "delete specific files/dirs by name"
re '\bsudo\b' "$c" && deny "sudo is not allowed for the agent"
re '\bchmod\s+(-R\s+)?777\b' "$c" && deny "chmod 777 is insecure"

# 5) Deploy / publish / infra changes → a human must approve
deploy='\b(terraform\s+(apply|destroy|import|state\s+rm)|kubectl\s+(apply|delete|scale|rollout|patch|edit|create|replace|drain)|helm\s+(install|upgrade|uninstall|rollback)|docker\s+push|npm\s+publish|yarn\s+publish|pnpm\s+publish|mvn\s+\S*\s*deploy|gradlew?\s+\S*publish|cargo\s+publish|twine\s+upload|gh\s+release\s+create|vercel\s+.*--prod|netlify\s+deploy\s+.*--prod|firebase\s+deploy|fly(ctl)?\s+deploy|serverless\s+deploy|aws\s+\S+\s+(delete|terminate|put-secret|update-secret|rm)|gcloud\s+.*\s(delete|deploy)|az\s+.*\s(delete|deploy)|psql\s+.*(prod|production)|DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE)'
# 6) Data: production targets/warehouses need a human
re '(--target[= ]+(prod|production)\b|\b(dbt|sqlmesh)\b.*\bprod(uction)?\b|airflow\s+(dags\s+(trigger|backfill|delete)|tasks\s+clear))' "$c" \
  && ask "data command against production / scheduler state: $cmd"

# 7) Local docker is fine via kit-run up/down; destroying data or images needs a human
re '\bdocker(-compose|\s+compose)?\s+.*\bdown\b.*\s(-v|--volumes)\b|\bdocker\s+(volume\s+(rm|prune)|system\s+prune|image\s+prune|rmi)\b' "$c" \
  && ask "destroys local Docker data/images: $cmd"
extra="$(cfg_hook ask_commands_extra)"
re "(?i)$deploy" "$c" && ask "deploy/publish/infra/destructive-data command: $cmd"
[ -n "$extra" ] && re "$extra" "$c" && ask "project rule (ask_commands_extra): $cmd"

exit 0
