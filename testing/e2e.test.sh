#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the 01-scaffold landing (the commit its first PR merges), run what
#      `checks.yml` runs on that PR — install with the lockfile the phase
#      pruned, render fixtures, typecheck, lint, test, build. That landing
#      WAITS on its checks, so a scaffold they refuse is a bootstrap that never
#      gets past phase one;
#   2. at the finished site, the same Checks sequence;
#   3. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `build-app` — the component's
#      buildCommand, the same step the deploy profile runs; `vite build`, where
#      @sveltejs/adapter-cloudflare writes `_worker.js` and the static output
#      to where wrangler.jsonc's `main` and `assets.directory` point —
#      `verify-build-output` (the component's `workerEntrypoint` and
#      `assetsDir`) and `deploy-dry-run` (`wrangler deploy --dry-run --config
#      wrangler.jsonc --name <reponame>-web-stage`, which bundles the adapter's
#      Worker). They run IN THE TREE THE RUNNER STAGES for the job
#      (testing/lib/stage-job.py), with the dependency layout the pinned
#      composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. (Run in a plain
#      checkout, the portfolio baseline's equivalent tier was green while its
#      first live bootstrap's lanes died in the lane layout.);
#   4. serve the built Worker with `wrangler dev` FROM THAT STAGED TREE and run
#      the component's OWN `smokeCommand` against it, verbatim — the check the
#      real deploy ends with — and then read every route the site promises:
#      the home page's heading and title carry the site's name (escaped, not
#      broken, by an `&` and an `'`), `/about` is pre-rendered and ships no
#      JavaScript, `/todos` runs in the Worker (its hook's cookie, its load,
#      a named form action), the static files and the hashed `_app` chunks
#      are served, and an unknown path is SvelteKit's 404 page.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false TURBO_TELEMETRY_DISABLED=1

# What checks.yml runs, step for step, read out of the workflow the site
# carries so the two cannot drift: every `run:` of its one job, in order.
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  while IFS= read -r cmd; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done < <(python3 - "$dir/.github/workflows/checks.yml" <<'PY'
import sys, yaml
wf = yaml.safe_load(open(sys.argv[1]))
for job in wf["jobs"].values():
    for step in job["steps"]:
        if "run" in step:
            print(step["run"].strip())
PY
)
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   3 phases placed and landed"

# ── 1. the scaffold's own pull request ─────────────────────────────────────
echo "── 01-scaffold's landing, under the checks its PR waits on"
git -C "$tree" worktree add -q "$scratch/at-01" "$(git -C "$tree" rev-parse HEAD~2)"
checks "$scratch/at-01" "$scratch/checks-01.log"

# ── 2. the finished site ───────────────────────────────────────────────────
echo "── the finished site, under the same checks"
checks "$tree" "$scratch/checks-site.log"

# ── 3. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: build-app, verify-build-output, deploy-dry-run"
s01="$(git -C "$tree" rev-parse HEAD~2)"; s02="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s01" --head "$s02" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 2
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/.svelte-kit" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done

# ── 4. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config wrangler.jsonc --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" <<'PY'
import html, json, re, sys, urllib.error, urllib.request
base, values = sys.argv[1], json.load(open(sys.argv[2]))
name = values["productname"]
problems = []
def bad(m): problems.append(m)
def get(path, data=None, headers=None):
    req = urllib.request.Request(base + path, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def text(fragment):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", fragment))).strip()
def title(page):
    m = re.search(r"<title>(.*?)</title>", page, re.S)
    return m and html.unescape(m.group(1))

# / — pre-rendered at build, served from the assets, the site's name on it.
status, _, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
h1 = re.search(r"<h1[^>]*>(.*?)</h1>", page, re.S)
if not h1 or text(h1.group(1)) != f"to your new {name}":
    bad(f"the home page's heading reads {h1 and text(h1.group(1))!r}, not 'to your new {name}'")
if title(page) != name:
    bad(f"the home page's <title> is {title(page)!r}, not {name!r}")
if "SvelteKit app" in page or "sveltekit-boilerplate" in page:
    bad("the home page still carries the baseline's name")
for nav in ('href="/"', 'href="/about"', 'href="/todos"'):
    if nav not in page:
        bad(f"the home page's nav has no {nav}")

# The hashed client chunks the home page boots from, and the static files.
chunks = sorted(set(re.findall(r"\./(_app/immutable/[^\"'\s)]+\.js)", page)))
if not chunks:
    bad("the home page references no _app/immutable chunk")
for chunk in chunks[:3]:
    s, h, _ = get("/" + chunk)
    if s != 200 or "javascript" not in (h.get("content-type") or ""):
        bad(f"/{chunk} answered {s} {h.get('content-type')}")
for path, ctype in (("/svelte-welcome.webp", "image/webp"), ("/svelte-welcome.png", "image/png"),
                    ("/favicon.png", "image/png"), ("/robots.txt", "text/plain")):
    s, h, _ = get(path)
    if s != 200 or not (h.get("content-type") or "").startswith(ctype):
        bad(f"{path} answered {s} {h.get('content-type')}, want 200 {ctype}")

# /about — pre-rendered, and ships no JavaScript (csr = dev).
s, _, body = get("/about")
about = body.decode()
if s != 200:
    bad(f"/about answered {s}")
if title(about) != f"About | {name}":
    bad(f"/about's <title> is {title(about)!r}, not 'About | {name}'")
if "<script" in about:
    bad("/about ships a <script>; it is pre-rendered without client-side rendering")

# /todos — rendered by the Worker: the server hook sets the visitor's cookie
# and the server load runs. The load reads api.svelte.dev, the hosted demo
# store this repository does not own: 200 when it answers, SvelteKit's 500
# page when it does not (it answers 500 to everything at the time of
# writing). Either is the Worker; a 404 or a missing cookie is not.
s, h, body = get("/todos")
if s not in (200, 500):
    bad(f"/todos answered {s}; the Worker renders it (200, or 500 from the demo API)")
if "userid=" not in (h.get("set-cookie") or ""):
    bad("/todos set no userid cookie — the server hook did not run")
if h.get("x-sveltekit-page") != "true":
    bad("/todos is not a SvelteKit page response")
if s == 200 and title(body.decode()) != f"Todos | {name}":
    bad(f"/todos's <title> is {title(body.decode())!r}, not 'Todos | {name}'")
print(f"     /todos: {s} (the demo API {'answered' if s == 200 else 'did not'}), the hook's cookie set")

# A named form action, as Kit's enhance posts it: the Worker runs `create`
# and answers an ActionResult (an `error` one if the demo API cannot be
# reached at all).
s, h, body = get("/todos?/create", data=b"text=from+the+e2e+tier",
                 headers={"content-type": "application/x-www-form-urlencoded",
                          "x-sveltekit-action": "true", "accept": "application/json",
                          "origin": base})
try:
    result = json.loads(body)
except ValueError:
    result = {}
if result.get("type") not in ("success", "error"):
    bad(f"POST /todos?/create answered {s} {body[:120]!r}, not an ActionResult")
else:
    print(f"     POST /todos?/create: the create action ran ({result['type']})")

# An unknown path is SvelteKit's own 404, rendered by the Worker in the layout.
s, _, body = get("/no-such-page")
nf = body.decode()
if s != 404 or "<h1>404</h1>" not in nf or 'href="/todos"' not in nf:
    bad(f"/no-such-page answered {s} without SvelteKit's 404 page")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, the _app chunks, the static files, /about, /todos and its create action, a 404 — the site's own")
PY

echo "e2e.test.sh: ok"
