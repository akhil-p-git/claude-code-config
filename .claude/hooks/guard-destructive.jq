# guard-destructive.jq: the analysis half of guard-destructive.sh.
# Reads the PreToolUse hook JSON, parses .tool_input.command (quote-, operator-,
# heredoc- and substitution-aware), and emits {"findings":[...]} where each finding
# is {level: deny|ask|check, rule, reason, ...}. It NEVER executes anything.
# "check" findings need repo state (git status / git clean -n / current branch) and
# are resolved by the bash wrapper.
#
# Args: --arg home "$HOME" --arg protected "<branch regex>" --arg projdir "$CLAUDE_PROJECT_DIR"

# ---------- lexing ----------
# ANSI-C strings ($'...') allow \' escapes, so they are matched before the plain-character class.
# A '#' that starts a word begins a comment running to end of line; comments are not commands.
def toks: [ scan("#[^\\n]*|[0-9]*(?:&>>?|>>?|<<<|<<-?|<>|<|>\\|)(?:&[0-9-]+)?|&&|\\|\\||\\|&|;;|[;|&\\n()]|(?:\\$'(?:[^'\\\\]|\\\\.)*'|[^\\s'\"\\\\;&|()<>]|\\\\.|\"(?:[^\"\\\\]|\\\\.)*\"|'[^']*')+") | select(startswith("#") | not) ];
def is_op: test("^(&&|\\|\\||\\|&|;;|[;|&\\n()])$");
def is_redir: test("^[0-9]*(?:&>>?|>>?|<<<|<<-?|<>|<|>\\|)(?:&[0-9-]+)?$");
def unquote: gsub("\\$'(?<x>(?:[^'\\\\]|\\\\.)*)'"; .x) | gsub("\"(?<x>(?:[^\"\\\\]|\\\\.)*)\""; .x) | gsub("'(?<x>[^']*)'"; .x) | gsub("\\\\(?<c>.)"; .c);
def base: sub("^.*/"; "");
def heredoc_re: "<<-?[ \\t]*(?<q>['\"]?)(?<t>[A-Za-z_][A-Za-z0-9_]*)\\k<q>(?<rest>[^\\n]*)\\n(?<body>[\\s\\S]*?)\\n[ \\t]*\\k<t>(?=\\n|$)";
def heredocs: [ match(heredoc_re; "g") | [.captures[] | {key: .name, value: .string}] | from_entries | .body ];
def strip_heredocs: gsub(heredoc_re; "<<__HEREDOC__\(.rest)");
# FIX3: bodies of QUOTED heredocs (<<'EOF') are literal text in bash: never scan them for $(...) / backticks.
def heredoc_q_re: "<<-?[ \\t]*(?<q>['\"])(?<t>[A-Za-z_][A-Za-z0-9_]*)\\k<q>(?<rest>[^\\n]*)\\n(?<body>[\\s\\S]*?)\\n[ \\t]*\\k<t>(?=\\n|$)";
def strip_quoted_heredocs: gsub(heredoc_q_re; "<<__HEREDOC__\(.rest)");
# $(...) (one nesting level) and `...` bodies, ignoring single-quoted text.
# Escaped \` and \$( are literal text, not substitutions; ANSI-C and single-quoted strings never expand.
def substs: gsub("\\\\[`$]"; "x") | gsub("\\$'(?:[^'\\\\]|\\\\.)*'"; "''") | gsub("'[^']*'"; "''") |
 [ (scan("\\$\\(((?:[^()]|\\([^()]*\\))*)\\)") | .[0]), (scan("`([^`]*)`") | .[0]) ];
# Variables assigned inside this same command (VAR=..., export VAR=..., for VAR in, read VAR).
def assigned_vars: [ (scan("(?:^|[\\s;&|(])(?:export\\s+|local\\s+|declare\\s+(?:-\\w+\\s+)?)?([A-Za-z_][A-Za-z0-9_]*)=") | .[0]),
                     (scan("\\bfor\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+in\\b") | .[0]),
                     (scan("\\bread\\s+(?:-[a-zA-Z]+\\s+)*([A-Za-z_][A-Za-z0-9_]*)") | .[0]) ] | unique;

# ---------- segments ----------
# tokens -> [{w:[words], redirs:[{op,target}], op_after}]
def segments:
  reduce (.[], "\n") as $t ({segs: [], cur: {w: [], redirs: []}, pending: null};
    if .pending != null then .cur.redirs += [{op: .pending, target: $t}] | .pending = null
    elif ($t | is_op) then
      (if ((.cur.w | length) > 0 or (.cur.redirs | length) > 0) then .segs += [.cur + {op_after: $t}] else . end)
      | .cur = {w: [], redirs: []}
    elif ($t | is_redir) then
      (if ($t | test("&[0-9-]+$")) then .cur.redirs += [{op: $t, target: null}] else .pending = $t end)
    else .cur.w += [$t] end)
  | .segs;

# Drop leading options; $witharg lists options that consume the next word.
def drop_opts($witharg):
  {w: ., done: false}
  | until(.done or (.w | length) == 0;
      .w[0] as $t
      | if $t == "--" then .w = .w[1:] | .done = true
        elif ($t | startswith("-")) and $t != "-" then
          (if ($witharg | any(. == $t)) then .w = .w[2:] else .w = .w[1:] end)
        else .done = true end)
  | .w;
def drop_assigns: until((length == 0) or ((.[0] | test("^[A-Za-z_][A-Za-z0-9_]*=")) | not); .[1:]);

# Strip env assignments and exec wrappers: sudo/doas/env/nice/timeout/xargs/npx/...
def wrapper_step:
  .w as $w | ($w[0] // "") as $c | ($c | base) as $b | ($w[1] // "") as $n |
  if ($c | test("^[A-Za-z_][A-Za-z0-9_]*=")) then .w = $w[1:]
  # FIX2: shell keywords that introduce a command ("do rm ...", "then git push ...", "{ rm ...; }", "! rm ...")
  elif (["do","then","else","elif","if","while","until","{","!"] | any(. == $c)) then .w = $w[1:]
  # FIX4: package-manager global options before the subcommand (pnpm --filter web exec prisma ..., pnpm -C dir ...)
  elif (["pnpm","npm","yarn","bun"] | any(. == $b)) and ($n | startswith("-")) then .w = ([$c] + ($w[1:] | drop_opts(["--filter","-F","-C","--dir","--prefix","-w","--workspace","--cwd"])))
  elif $b == "yarn" and $n == "workspace" then .w = ([$c] + $w[3:])
  elif $b == "sudo" or $b == "doas" or $b == "run0" then
    .sudo = true | .w = ($w[1:] | drop_opts(["-u","-g","-h","-p","-C","-D","-R","-T","-U","--user","--group","--host","--prompt","--chdir"]))
  elif $b == "env" then .w = ($w[1:] | drop_opts(["-u","--unset","-C","--chdir","-S","--split-string"]) | drop_assigns)
  elif $b == "nice" then .w = ($w[1:] | drop_opts(["-n","--adjustment"]))
  elif $b == "ionice" then .w = ($w[1:] | drop_opts(["-c","-n","-p","-t","--class","--classdata"]))
  elif $b == "timeout" then .w = ($w[1:] | drop_opts(["-s","-k","--signal","--kill-after"]) | .[1:])
  elif ["time","nohup","builtin","exec","unbuffer","nocorrect","noglob"] | any(. == $b) then .w = ($w[1:] | drop_opts([]))
  elif $b == "command" and ($n | test("^-[vV]") | not) then .w = ($w[1:] | drop_opts([]))
  elif $b == "stdbuf" then .w = ($w[1:] | drop_opts(["-i","-o","-e"]))
  elif $b == "xargs" then .xargs = true | .w = ($w[1:] | drop_opts(["-I","-i","-n","-P","-L","-l","-s","-d","-E","-e","-a","--arg-file","--delimiter","--max-args","--max-procs","--replace","--max-lines","--max-chars","--eof"]))
  elif $b == "watch" then .w = ($w[1:] | drop_opts(["-n","-d","--interval","--differences"]))
  elif $b == "npx" or $b == "bunx" or $b == "pnpx" then .w = ($w[1:] | drop_opts(["-p","--package","-c","--call"]))
  elif ($b == "pnpm" or $b == "yarn" or $b == "bun") and (["exec","dlx","x"] | any(. == $n)) then .w = ($w[2:] | drop_opts([]))
  elif $b == "npm" and $n == "exec" then .w = ($w[2:] | drop_opts(["-p","--package","-c","--call","-w","--workspace"]))
  elif ($b == "pnpm" or $b == "yarn" or $b == "bun") and (["prisma","drizzle-kit","vercel","vc","supabase","turso","neonctl"] | any(. == $n)) then .w = $w[1:]
  elif ($b == "uv" or $b == "poetry" or $b == "pipenv" or $b == "pdm" or $b == "hatch") and $n == "run" then .w = ($w[2:] | drop_opts(["--with","--python","-p","--env","-e"]))
  else .done = true end;
def strip_wrappers: {w: ., sudo: false, xargs: false, done: false} | until(.done or (.w | length) == 0; wrapper_step);

# ---------- paths ----------
def normpath($cwd):
  (if . == "~" then $home
   elif startswith("~/") then $home + .[1:]
   elif test("^\\$\\{?HOME\\}?(/|$)") then sub("^\\$\\{?HOME\\}?"; $home)
   elif test("^\\$\\{?PWD\\}?(/|$)") then (if $cwd == null then null else sub("^\\$\\{?PWD\\}?"; $cwd) end)
   elif test("^\\$\\{?CLAUDE_PROJECT_DIR\\}?(/|$)") then (if $projdir == "" then null else sub("^\\$\\{?CLAUDE_PROJECT_DIR\\}?"; $projdir) end)
   elif startswith("/") then .
   elif $cwd == null then null
   else $cwd + "/" + . end)
  | if . == null then null else
      (split("/") | reduce .[] as $p ([]; if $p == "" or $p == "." then . elif $p == ".." then (if length > 0 then .[:-1] else . end) else . + [$p] end)
       | "/" + join("/"))
    end;

def under($p; $root): $p == $root or ($p | startswith($root + "/"));
def depth_under($p; $root): ($p | ltrimstr($root + "/") | split("/") | length);

# Classify the target of a recursive delete/chmod. Returns null (unremarkable) or
# {cls, why}; callers map classes to decisions (rm is strictest, chmod -R loosest):
#   catastrophic  /, home, a parent of home/cwd, system or top-level dirs
#   hometop       a top-level folder of home (~/dev, ~/.config, ~/Documents)
#   cwd           the working directory / project root itself, or a glob matching all of it
#   dotgit        a .git directory
#   sensitive     ~/.config/x, ~/.ssh/x, ~/.claude/x ... (second level of credential/config dirs)
#   outside       outside the working directory (and not a temp/cache/build-artifact dir)
#   unresolved    built from command substitution or variables not set in this command
#   tmpglob       wildcard over the shared /tmp
def regenerable: test("^(node_modules|\\.next|dist|build|out|\\.turbo|\\.cache|__pycache__|\\.pytest_cache|\\.mypy_cache|\\.ruff_cache|\\.venv|venv|target|coverage|\\.nyc_output|\\.parcel-cache|\\.svelte-kit|\\.nuxt|\\.output|\\.vercel|\\.wrangler|\\.expo|storybook-static)$");
def classify_target($cwd; $assigned):
  . as $t |
  ($t | sub("(/\\*\\*?|/\\.\\*|/\\.?)+$"; "")) as $b0 |
  ($t | test("(/\\*\\*?|/\\.\\*)$")) as $contents |
  if $t == "" then {cls: "unresolved", why: "an empty target"}
  elif ($t | test("^(\\*|\\*\\*|\\.\\*|\\./\\*|\\./\\.\\*|\\*/|\\{\\.,\\}\\*|\\.\\[!.\\]\\*)$")) then {cls: "cwd", why: "a glob that matches everything in the working directory"}
  elif ($t | test("^\\.\\.(/\\.\\.)*/?$|^(\\.\\./)+\\.?/?$")) then {cls: "catastrophic", why: "a parent directory (\($t))"}
  elif ($t | test("^\\./?$")) then {cls: "cwd", why: "the current directory"}
  elif ($t | test("\\$\\(|`")) then {cls: "unresolved", why: "a path produced by command substitution (\($t))"}
  elif ($t | test("^(\\$\\{?HOME\\}?|~)/?(\\*|\\.\\*)?$")) then {cls: "catastrophic", why: "your home directory"}
  elif ($t | test("^\\$\\{?(TMPDIR|XDG_RUNTIME_DIR)\\}?/[^*]")) then null
  elif ($t | test("\\$\\{?(?!HOME\\b|PWD\\b|CLAUDE_PROJECT_DIR\\b)[A-Za-z_][A-Za-z0-9_]*")) then
    ([$t | scan("\\$\\{?([A-Za-z_][A-Za-z0-9_]*)") | .[0]] | map(select(. != "HOME" and . != "PWD" and . != "CLAUDE_PROJECT_DIR"))) as $vars |
    (if ($vars | all(. as $v | $assigned | any(. == $v))) then null
     else {cls: "unresolved", why: "a path built from shell variable(s) not set in this command (\($vars | join(", "))); if unset it expands toward / or the cwd. Use the literal path"} end)
  else
    ($b0 | if . == "" then "/" else . end | normpath($cwd)) as $p |
    if $p == null then null
    elif $p == "/" then {cls: "catastrophic", why: "the filesystem root"}
    elif ($p | base) == ".git" then {cls: "dotgit", why: "a .git directory (repository history)"}
    elif $p == $home then {cls: "catastrophic", why: "your home directory"}
    elif ($home | startswith($p + "/")) then {cls: "catastrophic", why: "a parent of your home directory (\($p))"}
    elif $cwd != null and ($cwd | startswith($p + "/")) then {cls: "catastrophic", why: "a parent of the working directory (\($p))"}
    elif ($p | test("^/(usr|etc|boot|bin|sbin|lib|lib32|lib64|sys|proc|dev)(/|$)")) then {cls: "catastrophic", why: "a system directory (\($p))"}
    elif ($p == "/tmp" or $p == "/var/tmp") then (if $contents then {cls: "tmpglob", why: "everything in the shared temp directory \($p) (wildcard)"} else {cls: "catastrophic", why: "a system directory (\($p))"} end)
    elif ($p | test("^/[^/]+$")) then {cls: "catastrophic", why: "a top-level directory (\($p))"}
    elif ($cwd != null and $p == $cwd) or ($projdir != "" and $p == $projdir) then {cls: "cwd", why: "the working directory / project root itself (\($p))"}
    elif under($p; "/tmp") or under($p; "/var/tmp") or under($p; "/dev/shm") then null
    elif ($p | base | regenerable) then null
    elif under($p; $home) then
      ($p | ltrimstr($home + "/") | split("/")) as $parts |
      ([".ssh",".gnupg",".aws",".claude",".config",".local",".kube",".docker",".password-store",".mozilla",".pki"] | any(. == $parts[0])) as $sens |
      if ($parts | length) == 1 and ([".cache",".npm",".pnpm-store","tmp",".Trash"] | any(. == $parts[0]) | not) then {cls: "hometop", why: "a top-level folder of your home directory (\($p))"}
      elif $sens and ($parts | length) == 2 then {cls: "sensitive", why: "a configuration/credential folder (\($p))"}
      elif ([".cache",".npm",".pnpm-store","tmp"] | any(. == $parts[0])) then null
      elif $cwd != null and (under($p; $cwd) | not) then {cls: "outside", why: "a path outside the working directory (\($p))"}
      else null end
    elif $cwd == null or (under($p; $cwd) | not) then {cls: "outside", why: "a path outside the working directory and home (\($p))"}
    else null end
  end;

def finding($lvl; $rule; $why): {level: $lvl, rule: $rule, reason: $why};

# ---------- secret paths ----------
def is_env_secret: test("(^|/)\\.env(\\.[A-Za-z0-9_.-]+)?$") and (test("(^|/)\\.env\\.(example|sample|template|dist|defaults|schema)(\\.|$)") | not);
def is_high_secret: test("(^|/)\\.ssh/(id_[A-Za-z0-9_-]+|[^/]+_(rsa|dsa|ecdsa|ed25519))$|(^|/)\\.aws/credentials$|(^|/)\\.config/gh/hosts\\.ya?ml$|(^|/)\\.claude/\\.credentials\\.json$|(^|/)\\.secrets\\.env$|(^|/)\\.netrc$|(^|/)\\.git-credentials$|(^|/)com\\.vercel\\.cli/auth\\.json$|(^|/)\\.docker/config\\.json$|(^|/)\\.kube/config$|(^|/)\\.gnupg/|(^|/)\\.password-store/|(^|/)\\.config/gcloud/(credentials\\.db|application_default_credentials\\.json|legacy_credentials)|^~?/?\\.npmrc$|^~?/?\\.pypirc$|/\\.npmrc$|/\\.pypirc$") and (test("\\.pub$") | not);
def is_secret: is_env_secret or is_high_secret;

# ---------- rules ----------
def rm_parse:
  reduce .[] as $t ({rec: false, npr: false, targets: [], eoo: false};
    if .eoo then .targets += [$t]
    elif $t == "--" then .eoo = true
    elif $t == "--recursive" then .rec = true
    elif $t == "--no-preserve-root" then .npr = true
    elif ($t | test("^--")) then .
    elif ($t | test("^-[a-zA-Z]+$")) then (if ($t | test("[rR]")) then .rec = true else . end)
    else .targets += [$t] end);

def rule_rm($a; $ctx):
  ($a | rm_parse) as $p |
  if $p.npr then [finding("deny"; "rm"; "rm --no-preserve-root")]
  elif ($p.rec | not) then []
  else [ $p.targets[] | classify_target($ctx.cwd; $ctx.assigned) | select(. != null) | . as $k |
         finding(if (["catastrophic","hometop","cwd","dotgit"] | any(. == $k.cls)) then "deny" else "ask" end; "rm"; "recursive delete of \($k.why)") ] end;

def rule_find($a; $ctx):
  ([$a | to_entries[] | select(.value | test("^[-(!]")) | .key] | first // ($a | length)) as $i |
  ($a[:$i] | if length == 0 then ["."] else . end) as $paths |
  ($a[$i:]) as $expr |
  (($expr | any(. == "-delete")) or ([$expr | to_entries[] | select(.value | test("^-(exec|execdir|ok|okdir)$")) | $expr[.key + 1] // "" | base] | any(test("^(rm|shred|unlink)$")))) as $del |
  ($expr | any(test("^-(name|iname|path|ipath|wholename|regex|iregex|mtime|mmin|newer|size|empty|user|group)$"))) as $filtered |
  if $del then
    [ $paths[] | classify_target($ctx.cwd; $ctx.assigned) | select(. != null and (.cls != "cwd" or ($filtered | not))) |   # FIX5: unfiltered find over the cwd itself
      if (.cls == "catastrophic" or .cls == "hometop" or .cls == "cwd") and ($filtered | not) then finding("deny"; "find"; "find -delete/-exec rm over \(.why)")
      elif .cls == "dotgit" then finding("deny"; "find"; "find -delete inside \(.why)")
      else finding("ask"; "find"; "find -delete/-exec rm over \(.why)") end ]
  else [] end;

def rule_perm($c; $a; $ctx):
  ($a | any(. == "-R" or . == "--recursive" or test("^-[a-zA-Z]*R[a-zA-Z]*$"))) as $rec |
  [$a[] | select(startswith("-") | not)] as $pos |
  ( if $rec then [ $pos[1:][] | classify_target($ctx.cwd; $ctx.assigned) | select(. != null and .cls == "catastrophic") | finding("deny"; $c; "recursive \($c) of \(.why)") ] else [] end )
  + ( if $c == "chmod" and (($pos[0] // "") | test("^0*777$|^0*666$|^(a|o|ugo)?\\+[rx]*w[rx]*$|^a=rwx$")) then [finding("ask"; "chmod"; "world-writable permissions (\($pos[0]))")] else [] end );

def rule_disk($c; $a):
  if ($c | test("^(mkfs(\\..+)?|mke2fs|mkswap|wipefs|fdisk|sfdisk|cfdisk|parted|gdisk|sgdisk|blkdiscard|shred)$")) then [finding("deny"; "disk"; "\($c) destroys data on disks/partitions or files irreversibly")]
  elif $c == "dd" and ($a | any(test("^of=/dev/(sd[a-z]|nvme[0-9]|hd[a-z]|vd[a-z]|xvd[a-z]|mmcblk[0-9]|md[0-9]|dm-[0-9]|disk|loop[0-9]|mapper/)"))) then [finding("deny"; "dd"; "dd writing to a block device")]
  else [] end;

def git_parse($cwd):
  {a: ., dir: $cwd, sub: null, done: false}
  | until(.done or (.a | length) == 0;
      .a[0] as $t |
      if $t == "-C" then .dir as $d0 | (.a[1] // "") as $p | .dir = (if $p == "" then $d0 else ($p | normpath($d0)) end) | .a = .a[2:]
      elif $t == "-c" or $t == "--git-dir" or $t == "--work-tree" or $t == "--namespace" or $t == "--exec-path" then .a = .a[2:]
      elif ($t | startswith("-")) then .a = .a[1:]
      else .sub = $t | .a = .a[1:] | .done = true end)
  | {dir, sub, args: .a};

def protected_branch: test("^(" + $protected + ")$");
def push_parse:
  reduce .[] as $t ({force: false, lease: false, mirror: false, del: false, noverify: false, pos: [], skip: false};
    if .skip then .skip = false
    elif $t == "-o" or $t == "--push-option" or $t == "--repo" or $t == "--receive-pack" or $t == "--exec" then .skip = true
    elif $t == "--force" then .force = true
    elif ($t | test("^--force-with-lease")) or $t == "--force-if-includes" then .lease = true
    elif $t == "--mirror" then .mirror = true
    elif $t == "--delete" then .del = true
    elif $t == "--no-verify" then .noverify = true
    elif ($t | test("^-[a-zA-Z]+$")) then
      (if ($t | test("f")) then .force = true else . end) | (if ($t | test("d")) then .del = true else . end)
    elif ($t | startswith("-")) then .
    else .pos += [$t] end);

def rule_git_push($g):
  ($g.args | push_parse) as $p |
  ($p.pos[1:]) as $refs |
  ([ $refs[] | select(startswith("+")) ] | length > 0) as $plus |
  ([ $refs[] | ltrimstr("+") | (if test(":") then sub("^[^:]*:"; "") else . end) | sub("^refs/heads/"; "") ]) as $dst |
  ([ $refs[] | select(startswith(":")) | ltrimstr(":") | sub("^refs/heads/"; "") ]) as $dels |
  ($dst | map(select(. != "" and . != "HEAD"))) as $named |
  (($dst | length) == 0 or ($dst | any(. == "HEAD"))) as $implicit |
  ($p.force or $plus) as $force |
  ($named | any(protected_branch)) as $prot |
  ( if $p.mirror then [finding("deny"; "git-push"; "git push --mirror overwrites and deletes every remote ref")] else [] end )
  + ( if ($dels | any(protected_branch)) or ($p.del and $prot) then [finding("deny"; "git-push"; "deleting a protected remote branch (\(($dels + $named) | unique | join(", ")))")]
      elif ($dels | length) > 0 or $p.del then [finding("ask"; "git-push"; "deleting remote branch(es) \(($dels + $named) | unique | join(", "))")]
      else [] end )
  + ( if $force and ($p.del | not) then
        (if $prot then [finding("deny"; "git-push"; "force-push to protected branch \($named | map(select(protected_branch)) | join(", "))")]
         elif $implicit then [{level: "check", check: "branch", dir: $g.dir, rule: "git-push", if_protected: "deny", otherwise: "ask", reason: "force-push"}]
         else [finding("ask"; "git-push"; "force-push rewrites remote history (\($named | join(", ")))")] end)
      elif $p.lease then
        (if $prot then [finding("ask"; "git-push"; "force-with-lease push to protected branch \($named | join(", "))")]
         elif $implicit then [{level: "check", check: "branch", dir: $g.dir, rule: "git-push", if_protected: "ask", otherwise: null, reason: "force-with-lease push"}]
         else [] end)
      else [] end )
  + ( if $p.noverify then [finding("ask"; "git-push"; "--no-verify skips the repository's pre-push hooks")] else [] end );

def pathspec_wide: any(. == "." or . == ":/" or . == "*" or . == ":(top)" or . == "./" or test("^:/?$"));
def rule_git($a; $ctx):
  ($a | git_parse($ctx.cwd)) as $g | $g.args as $r |
  if $g.sub == "push" then rule_git_push($g)
  elif $g.sub == "reset" and ($r | any(. == "--hard")) then
    [{level: "check", check: "tracked", dir: $g.dir, rule: "git-reset", reason: "git reset --hard would discard uncommitted changes"}]
  elif $g.sub == "checkout" and (($r | any(. == "-f" or . == "--force")) or ($r | pathspec_wide)) then
    [{level: "check", check: "tracked", dir: $g.dir, rule: "git-checkout", reason: "this git checkout would discard uncommitted changes"}]
  elif $g.sub == "switch" and ($r | any(. == "-f" or . == "--force" or . == "--discard-changes")) then
    [{level: "check", check: "tracked", dir: $g.dir, rule: "git-switch", reason: "git switch --discard-changes would discard uncommitted changes"}]
  elif $g.sub == "restore" and ($r | pathspec_wide) and (($r | any(. == "--staged" or . == "-S")) and ($r | any(. == "--worktree" or . == "-W")) | not) and ($r | any(. == "--staged" or . == "-S") | not) then
    [{level: "check", check: "tracked", dir: $g.dir, rule: "git-restore", reason: "git restore of the whole tree would discard uncommitted changes"}]
  elif $g.sub == "clean" and ($r | any(. == "--force" or test("^-[a-zA-Z]*f"))) and ($r | any(. == "-n" or . == "--dry-run" or . == "-i" or . == "--interactive" or test("^-[a-zA-Z]*n")) | not) then
    [{level: "check", check: "clean", dir: $g.dir, rule: "git-clean",
      d: ($r | any(test("^-[a-zA-Z]*d"))), x: ($r | any(test("^-[a-zA-Z]*x"))), X: ($r | any(test("^-[a-zA-Z]*X"))),
      paths: ([$r[] | select(startswith("-") | not)]), reason: "git clean -f permanently deletes untracked files"}]
  elif $g.sub == "stash" and (($r[0] // "") == "drop" or ($r[0] // "") == "clear") then [finding("ask"; "git-stash"; "git stash \($r[0]) permanently discards stashed work")]
  elif $g.sub == "branch" and ($r | any(. == "-D" or test("^-[a-zA-Z]*D"))) and ($r | any(protected_branch)) then [finding("ask"; "git-branch"; "force-deleting protected branch \([$r[] | select(protected_branch)] | join(", "))")]
  elif $g.sub == "filter-branch" or $g.sub == "filter-repo" then [finding("ask"; "git-history"; "git \($g.sub) rewrites repository history")]
  elif $g.sub == "reflog" and (($r[0] // "") == "expire" or ($r[0] // "") == "delete") then [finding("ask"; "git-history"; "git reflog \($r[0]) destroys the recovery log")]
  elif $g.sub == "gc" and ($r | any(test("^--prune=(now|all)"))) then [finding("ask"; "git-history"; "git gc --prune=now makes lost commits unrecoverable")]
  elif $g.sub == "update-ref" and ($r | any(. == "-d")) then [finding("ask"; "git-history"; "git update-ref -d deletes a ref")]
  elif $g.sub == "remote" and (["set-url","add","remove","rm","rename"] | any(. == ($r[0] // ""))) then [finding("ask"; "git-remote"; "git remote \($r[0]) changes where pushes go")]
  elif $g.sub == "commit" and ($r | any(. == "--no-verify" or . == "-n")) then [finding("ask"; "git-commit"; "--no-verify skips the repository's pre-commit hooks (e.g. secret scanning)")]
  elif $g.sub == "worktree" and ($r[0] // "") == "remove" and ($r | any(. == "-f" or . == "--force")) then [finding("ask"; "git-worktree"; "git worktree remove --force discards that worktree's uncommitted changes")]
  elif $g.sub == "rm" and ($r | any(. == "-r" or test("^-[a-zA-Z]*r"))) and ($r | pathspec_wide) and ($r | any(. == "--cached") | not) then [finding("ask"; "git-rm"; "git rm -r on the whole tree")]
  else [] end;

def sql_text: ascii_downcase;
def rule_sql($c; $a; $bodies):
  (($a + $bodies) | join(" ") | sql_text) as $s |
  ($s | split(";")) as $stmts |
  ( if ($s | test("\\bdrop\\s+(database|schema)\\b")) then [finding("deny"; "sql"; "DROP DATABASE/SCHEMA via \($c)")] else [] end )
  + ( if ($s | test("\\bdrop\\s+table\\b|\\btruncate\\s+(table\\s+)?[a-z_\"]")) then [finding("ask"; "sql"; "DROP TABLE/TRUNCATE via \($c)")] else [] end )
  + ( if ($stmts | any(test("\\bdelete\\s+from\\s+\\S+") and (test("\\bwhere\\b") | not))) then [finding("ask"; "sql"; "DELETE without WHERE via \($c)")] else [] end )
  + ( if ($stmts | any(test("\\bupdate\\s+\\S+\\s+set\\b") and (test("\\bwhere\\b") | not))) then [finding("ask"; "sql"; "UPDATE without WHERE via \($c)")] else [] end )
  + ( if $c == "redis-cli" and ($s | test("\\bflush(all|db)\\b")) then [finding("deny"; "redis"; "redis FLUSHALL/FLUSHDB")] else [] end )
  + ( if ($c == "mongosh" or $c == "mongo") and ($s | test("dropdatabase\\(|\\.drop\\(")) then [finding("ask"; "mongo"; "MongoDB drop")] else [] end );

def rule_dbtools($c; $a):
  ($a | join(" ")) as $s |
  if $c == "dropdb" then [finding("deny"; "db"; "dropdb deletes a PostgreSQL database")]
  elif $c == "prisma" and ($s | test("^migrate\\s+reset\\b")) then [finding("ask"; "db"; "prisma migrate reset drops and recreates the database (check DATABASE_URL is not production)")]
  elif $c == "prisma" and ($s | test("^db\\s+push\\b")) and ($s | test("--force-reset|--accept-data-loss")) then [finding("ask"; "db"; "prisma db push with --force-reset/--accept-data-loss can drop data")]
  elif $c == "drizzle-kit" and (($s | test("^drop\\b")) or (($s | test("^push\\b")) and ($s | test("--force")))) then [finding("ask"; "db"; "drizzle-kit \($a[0]) can drop data without prompting")]
  elif $c == "supabase" and ($s | test("^db\\s+(reset|push)\\b|^projects\\s+delete\\b|^branches\\s+delete\\b")) then [finding("ask"; "db"; "supabase \($a[0:2] | join(" ")) modifies or resets a (possibly remote) database")]
  elif $c == "neonctl" and ($s | test("\\b(delete|reset|restore)\\b")) then [finding("ask"; "db"; "neonctl destructive operation")]
  elif $c == "turso" and ($s | test("^db\\s+destroy\\b")) then [finding("ask"; "db"; "turso db destroy")]
  elif ($c == "rails" or $c == "rake") and ($s | test("\\bdb:(drop|reset|purge|schema:load)\\b")) then [finding("ask"; "db"; "\($c) database reset/drop")]
  elif ($c | test("^python3?$")) and ($s | test("manage\\.py\\s+(flush|reset_db|sqlflush)\\b")) then [finding("ask"; "db"; "Django database flush/reset")]
  else [] end;

def rule_platform($c; $a):
  ($a | join(" ")) as $s | ($a[0] // "") as $s0 | ($a[1] // "") as $s1 |
  if ($c == "vercel" or $c == "vc") then
    ( if ($a | any(. == "--prod" or . == "--production" or . == "--target=production")) or ($s | test("--target\\s+production")) then [finding("ask"; "vercel"; "production deployment on Vercel")] else [] end )
    + ( if (["promote","rollback","remove","rm","redeploy"] | any(. == $s0)) then [finding("ask"; "vercel"; "vercel \($s0) changes what production serves or deletes deployments")] else [] end )
    + ( if (["env","domains","domain","dns","alias","aliases","project","projects","certs","cert","secrets","integration","blob","edge-config"] | any(. == $s0)) and (["rm","remove","delete","pull"] | any(. == $s1) and $s1 != "pull") then [finding("ask"; "vercel"; "vercel \($s0) \($s1) deletes a Vercel resource")] else [] end )
  elif (["npm","pnpm","yarn","bun"] | any(. == $c)) and (["publish","unpublish","deprecate"] | any(. == $s0) or ($s0 == "npm" and $s1 == "publish")) then [finding("ask"; "publish"; "\($c) \($s0) publishes to a package registry")]
  elif ($c == "cargo" and (["publish","yank","owner"] | any(. == $s0))) or ($c == "twine" and $s0 == "upload") or ($c == "gem" and (["push","yank"] | any(. == $s0))) or (["uv","poetry","flit","hatch","pdm"] | any(. == $c) and $s0 == "publish") then [finding("ask"; "publish"; "\($c) \($s0) publishes to a package registry")]
  elif $c == "gh" then
    if $s0 == "repo" and $s1 == "delete" then [finding("deny"; "gh"; "gh repo delete permanently deletes a GitHub repository")]
    elif $s0 == "repo" and (["archive","rename","transfer"] | any(. == $s1)) then [finding("ask"; "gh"; "gh repo \($s1)")]
    elif $s0 == "repo" and $s1 == "edit" and ($s | test("--visibility")) then [finding("ask"; "gh"; "gh repo edit --visibility changes who can see the repository")]
    elif $s0 == "repo" and $s1 == "create" and ($a | any(. == "--public")) then [finding("ask"; "gh"; "creating a public repository")]
    elif $s0 == "pr" and $s1 == "merge" then [finding("ask"; "gh"; "gh pr merge merges into the base branch")]
    elif $s0 == "release" and ($s1 | test("^delete")) then [finding("ask"; "gh"; "gh release \($s1)")]
    elif ($s0 == "secret" or $s0 == "variable") and (["set","delete","remove"] | any(. == $s1)) then [finding("ask"; "gh"; "gh \($s0) \($s1) changes repository secrets/variables")]
    elif $s0 == "auth" and ($s1 == "token" or ($s1 == "status" and ($a | any(. == "-t" or . == "--show-token")))) then [finding("ask"; "gh"; "this prints a live GitHub token into the transcript")]
    elif $s0 == "api" and ($s | test("(-X|--method)[ =]?(DELETE|delete)\\b")) then [finding("ask"; "gh"; "gh api DELETE request")]
    elif $s0 == "gist" and $s1 == "create" and ($a | any(. == "--public" or . == "-p")) then [finding("ask"; "gh"; "creating a public gist")]
    elif ($s0 == "ssh-key" or $s0 == "gpg-key") and (["add","delete"] | any(. == $s1)) then [finding("ask"; "gh"; "gh \($s0) \($s1) changes account credentials")]
    else [] end
  elif ($c == "docker" or $c == "podman") then
    ( if $s0 == "system" and $s1 == "prune" and ($a | any(. == "-a" or . == "--all" or . == "--volumes" or test("^-[a-zA-Z]*a"))) then [finding("ask"; "docker"; "docker system prune -a/--volumes deletes images and possibly data volumes")] else [] end )
    + ( if $s0 == "volume" and (["rm","remove","prune"] | any(. == $s1)) then [finding("ask"; "docker"; "docker volume \($s1) deletes persistent data")] else [] end )
    + ( if $s0 == "compose" and ($a | any(. == "down")) and ($a | any(. == "-v" or . == "--volumes")) then [finding("ask"; "docker"; "docker compose down -v deletes the project's data volumes")] else [] end )
    + ( if (["run","create"] | any(. == $s0)) and ($a | any(. == "--privileged" or test("^(--volume=|-v=?)?/:/") or test("^--pid=host$") or test("docker\\.sock"))) then [finding("ask"; "docker"; "container gets host-level access (--privileged, / mount, host pid, or docker.sock)")] else [] end )
    + ( if $s0 == "push" then [finding("ask"; "docker"; "docker push publishes an image")] else [] end )
  elif $c == "docker-compose" and ($a | any(. == "down")) and ($a | any(. == "-v" or . == "--volumes")) then [finding("ask"; "docker"; "docker-compose down -v deletes data volumes")]
  elif $c == "kubectl" and (["delete","drain","replace"] | any(. == $s0)) then [finding("ask"; "infra"; "kubectl \($s0)")]
  elif $c == "helm" and (["uninstall","delete"] | any(. == $s0)) then [finding("ask"; "infra"; "helm \($s0)")]
  elif ($c == "terraform" or $c == "tofu" or $c == "terragrunt") and ($s0 == "destroy" or ($s0 == "apply" and ($a | any(test("^-auto-approve"))))) then [finding("ask"; "infra"; "\($c) \($s0) changes real infrastructure")]
  elif $c == "pulumi" and ($s0 == "destroy" or ($s0 == "up" and ($a | any(. == "--yes" or . == "-y")))) then [finding("ask"; "infra"; "pulumi \($s0)")]
  elif $c == "aws" and (($s | test("^s3\\s+(rm|rb)\\b")) or ($s | test("\\s(delete|terminate|remove)-[a-z-]+"))) then [finding("ask"; "infra"; "aws destructive operation")]
  elif ($c == "gcloud" or $c == "az") and ($a | any(. == "delete")) then [finding("ask"; "infra"; "\($c) ... delete")]
  else [] end;

def upload_paths($c; $a):
  [ range(0; $a | length) as $i | $a[$i] as $t |
    ( if ($t | test("^@.")) then ($t | ltrimstr("@")) else empty end ),
    ( if ($t | test("^[^=@<]+=[@<].")) then ($t | sub("^[^=@<]+=[@<]"; "") | sub(";.*$"; "")) else empty end ),
    ( if (["-T","--upload-file","--data-binary","--data","-d","--data-urlencode","-F","--form"] | any(. == $t)) then ($a[$i + 1] // "" | sub("^[^=@<]*=?[@<]?"; "") ) else empty end ),
    ( if ($t | test("^--(post|body)-file=")) then ($t | sub("^--(post|body)-file="; "")) else empty end ) ];

def rule_exfil($c; $a; $redirs):
  if (["curl","wget","http","https","xh","httpie"] | any(. == $c)) then
    [ upload_paths($c; $a)[] | select(is_secret or (normpath(null) // "" | is_high_secret)) | finding("deny"; "exfil"; "uploading credential file \(.) to a remote host") ]
  elif (["scp","rsync","sftp","rclone"] | any(. == $c)) then
    [ $a[] | select(startswith("-") | not) | select(test("^[^/]*:") | not) | select(is_secret or (normpath(null) // "" | is_high_secret)) | finding("deny"; "exfil"; "copying credential file \(.) to another host") ]
  elif (["nc","ncat","netcat","socat","telnet"] | any(. == $c)) then
    [ $redirs[] | select(.op | test("^[0-9]*<$")) | .target // "" | select(is_secret) | finding("deny"; "exfil"; "sending credential file \(.) over the network") ]
  elif (["base64","xxd","od","hexdump","strings","cat","less","more","head","tail","cp","tar","zip","7z","gpg","openssl","bat","nl","rev","tac"] | any(. == $c)) then
    [ $a[] | select(startswith("-") | not) | select(is_high_secret or ((. as $x | try ($x | normpath(null)) catch null) // "" | is_high_secret)) | finding("deny"; "secret-read"; "reading credential store \(.) (its contents would land in the transcript)") ]
  else [] end;

def downloader: test("^(curl|wget|fetch|http|https|xh|aria2c)$");
def shells: test("^(bash|sh|zsh|dash|ksh|ash|fish|mksh)$");
def interpreters: test("^(python[0-9.]*|node|nodejs|perl|ruby|php|deno|bun|lua)$");
def execs_stdin($c; $a):
  if ($c | shells) then ($a | any(test("^-[a-zA-Z]*c[a-zA-Z]*$")) | not) and ([$a[] | select(startswith("-") | not)] | length == 0 or (.[0] == "-"))
  elif ($c | interpreters) then
    ($a | any(. == "-c" or . == "-e" or . == "-m" or . == "-p" or . == "--eval" or . == "--print" or . == "-r" or . == "run")) as $inline |
    ([$a[] | select(startswith("-") | not)]) as $pos |
    ($inline | not) and (($pos | length) == 0 or $pos[0] == "-")
  else false end;

# ---------- per-command dispatch ----------
def analyze($cmd; $cwd0; $depth):
  if $depth > 3 or ($cmd | length) == 0 then []
  else
  ($cmd | heredocs) as $hds |
  ($cmd | assigned_vars) as $assigned |
  ($cmd | strip_heredocs | gsub("\\\\\\n"; " ") | toks | segments) as $segs |   # FIX1: backslash-newline is a line continuation, not a separator
  # pass 1: summaries with sequential cwd tracking
  (reduce $segs[] as $s ({cwd: $cwd0, hd: 0, out: []};
     ($s.w | map(unquote) | strip_wrappers) as $st |
     ($st.w[0] // "" | base) as $c | ($st.w[1:]) as $a |
     ([$s.redirs[] | select(.target == "__HEREDOC__")] | length) as $nhd |
     ($hds[.hd:(.hd + $nhd)]) as $bodies |
     .out += [{c: $c, a: $a, sudo: $st.sudo, xargs: $st.xargs, redirs: $s.redirs, op_after: $s.op_after, cwd: .cwd, bodies: $bodies}]
     | .hd += $nhd
     | if ($c == "cd" or $c == "pushd") then
         ($a | map(select(startswith("-") | not)) | .[0] // "~") as $d | .cwd as $cw |
         .cwd = (if ($d | test("^\\$\\{?(HOME|PWD)\\}?(/|$)")) then ($d | normpath($cw))
                 elif ($d | test("\\$|`|^-$")) then null else ($d | normpath($cw)) end)
       else . end
  ) | .out) as $sum |
  ($sum | to_entries | map(.value + {i: .key})) as $S |
  (
    # pass 2: per-segment rules
    [ $S[] | . as $x | {cwd: $x.cwd, assigned: $assigned} as $ctx |
      ( if $x.c == "rm" then rule_rm($x.a; $ctx)
        elif $x.c == "find" then rule_find($x.a; $ctx)
        elif $x.c == "git" then rule_git($x.a; $ctx)
        elif (["chmod","chown","chgrp"] | any(. == $x.c)) then rule_perm($x.c; $x.a; $ctx)
        elif (["psql","mysql","mariadb","sqlite3","duckdb","sqlcmd","cockroach","clickhouse-client","mongosh","mongo","redis-cli","pgcli","mycli","litecli"] | any(. == $x.c)) then rule_sql($x.c; $x.a; $x.bodies)
        elif (["dropdb","prisma","drizzle-kit","supabase","neonctl","turso","rails","rake","python","python3"] | any(. == $x.c)) then rule_dbtools($x.c; $x.a)
        else [] end )[],
      rule_disk($x.c; $x.a)[],
      rule_platform($x.c; $x.a)[],
      rule_exfil($x.c; $x.a; $x.redirs)[],
      ( [$x.redirs[] | select(.target != null) | .target | unquote | select(test("^/dev/(sd[a-z]|nvme[0-9]|hd[a-z]|vd[a-z]|xvd[a-z]|mmcblk[0-9]|md[0-9]|dm-[0-9]|disk|mapper/)"))]
        | if length > 0 then finding("deny"; "device"; "redirecting output onto a block device") else empty end ),
      ( if $x.sudo and ($x.c != "true") and (["-v","-k","-l"] | any(. == $x.c) | not) then finding("ask"; "sudo"; "runs as root: \(([$x.c] + $x.a) | join(" ") | .[0:120])") else empty end ),
      # recursion: shell -c strings, eval, ssh remote commands, heredocs fed to a shell
      ( if ($x.c | shells) then
          ([ $x.a | to_entries[] | select(.value | test("^-[a-zA-Z]*c[a-zA-Z]*$")) | .key ] | first) as $ci |
          (if $ci != null then analyze(($x.a[$ci + 1] // ""); $x.cwd; $depth + 1)[] else empty end),
          (if $ci == null then ($x.bodies[] | analyze(.; $x.cwd; $depth + 1)[]) else empty end)
        else empty end ),
      ( if $x.c == "eval" then analyze(($x.a | join(" ")); $x.cwd; $depth + 1)[] else empty end ),
      ( if $x.c == "ssh" then
          ($x.a | drop_opts(["-p","-i","-o","-l","-J","-F","-L","-R","-D","-b","-c","-E","-e","-m","-O","-Q","-S","-W","-w","-B","-I"])) as $r |
          ((if ($r | length) > 1 then analyze(($r[1:] | join(" ")); null; $depth + 1)[] else empty end),
           ($x.bodies[] | analyze(.; null; $depth + 1)[]))
        else empty end ),
      ( if $x.c == "find" then
          ([ $x.a | to_entries[] | select(.value | test("^-(exec|execdir)$")) | .key ] | first) as $ei |
          (if $ei != null and (($x.a[$ei + 1] // "" | base) | shells) then analyze(([$x.a[($ei + 1):][] | select(. != ";" and . != "+" and . != "\\;")] | .[2:] | .[0] // ""); $x.cwd; $depth + 1)[] else empty end)
        else empty end )
    ]
    # pass 3: download piped into an interpreter (anywhere later in the same pipeline)
    + [ $S[] | . as $x | select($x.c | interpreters or shells) | select(execs_stdin($x.c; $x.a)) |
        ( [ $S[] | select(.i < $x.i) ] | reverse | . as $prev |
          ( reduce $prev[] as $p ({ok: true, hit: false}; if .ok and ($p.op_after == "|" or $p.op_after == "|&") then (if ($p.c | downloader) then .hit = true else . end) else .ok = false end) ).hit ) |
        select(.) | finding("deny"; "pipe-to-shell"; "piping a download straight into \($x.c); download to a file, inspect it, then run it") ]
    # substitutions
    + [ ($cmd | strip_quoted_heredocs | substs)[] | analyze(.; $cwd0; $depth + 1)[] ]
    # raw patterns
    + ( if ($cmd | test(":\\s*\\(\\s*\\)\\s*\\{[^}]*:\\s*\\|\\s*:\\s*&")) then [finding("deny"; "fork-bomb"; "fork bomb")] else [] end )
    + ( if ($cmd | test("(^|[;&|(\\s])(bash|sh|zsh|dash|ksh|source|\\.)\\s+<\\(\\s*(curl|wget)\\b")) or ($cmd | test("\\b(bash|sh|zsh|dash|ksh|eval)\\b[^\\n]*\\$\\(\\s*(curl|wget)\\b"))
        then [finding("deny"; "pipe-to-shell"; "executing a script fetched from the network; download, inspect, then run it")] else [] end )
  )
  end;

# One line per finding (no output = nothing found), so the wrapper needs no more jq.
# Fields are \u001f-separated (a non-whitespace IFS keeps empty fields in bash read):
# level, check, dir, reason, d, x, X, if_protected, otherwise, paths (\u001e-joined)
( try (analyze((.tool_input.command // ""); (.cwd // null); 0) | unique_by([.level, .rule, .reason, .check // ""]))
  catch [finding("ask"; "guard-error"; "guard could not analyze this command (\(.)); approve manually if it is safe")] )
| .[] | [.level, (.check // ""), (.dir // ""), .reason, ((.d // false) | tostring), ((.x // false) | tostring), ((.X // false) | tostring),
         (.if_protected // ""), (.otherwise // ""), ((.paths // []) | join("\u001e"))]
| map(tostring | gsub("[\\n\\r\\t\u001f]"; " ")) | join("\u001f")
