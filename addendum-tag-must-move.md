# Addendum — "a changed package must bump its tag"

Apply to **PR 67** (`platform-packages`) and **PR 32** (`sandbox-dependencies`),
or land as a small follow-up PR. Two files: one new script, one new CI job.

## Why

Once publish-on-merge is gone and the guard skips tags that already exist, a
package edited **without** a tag bump is silently never published. Git has the
change, the registry does not, the cluster does not, and nothing says so.

Replayed against the last 40 package-touching commits in `platform-packages`:

    would fail the PR : 18
      of which docs/chore (false positives) : 1
    would pass        : 22

Across the full history, **24 of 71 package edits shipped without a tag bump** —
about one in three. Today they ship by overwriting a published tag. After PR 67
they would not ship at all. Examples:

    feat(trino): add opa status and decision log        tag stayed 480.0.0-p07
    feat(trino)!: take catalogs as two lists            tag stayed 480.0.0-p18
    fix(superset): keep a local admin when OIDC is off  tag stayed 6.0.0-p02
    feat(polaris): publish the in-cluster catalog URI   tag stayed 1.3.0-incubating-p02

## Scope: this is temporary

It exists only for the window between PR 67 and Phase 2. Once release-please owns
the tag, the version comes from the commit type — `fix:` and `feat:` publish,
`docs:` and `chore:` do not — and developers never touch `tag:` at all. **PR 3
must delete this job and this script.**

## 1. New file: `.github/scripts/tag-must-move.sh`

```bash
#!/usr/bin/env bash
#
# The published version is a literal in each package manifest, and the publish
# job skips any tag that already exists. So a package edited without a tag bump
# is never published: git has the change, the registry does not, and nothing
# says so.
#
# This fails the pull request instead.
#
# Interim guard: once release-please owns the tag, the version comes from the
# commit type and this script must be removed.
#
# Usage: tag-must-move.sh <base-ref> <changed-file>...
set -uo pipefail

base="$1"; shift
changed=("$@")
[[ ${#changed[@]} -eq 0 ]] && exit 0

status=0

# Package directories touched by files that can affect the built artifact.
# README and docs cannot, so they never require a bump.
dirs=$(printf '%s\n' "${changed[@]}" \
       | grep -E '^packages/.*\.ya?ml$' \
       | grep -viE '/README\.md$|^packages/.*/docs/' \
       | xargs -r -n1 dirname | sort -u)

for dir in ${dirs}
do
  manifest=$(find "${dir}" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l '^modules:' {} \;)
  [[ -z "${manifest}" ]] && continue

  new=$(grep -m1 -E '^tag:' "${manifest}" | sed 's/^tag: *//')
  old=$(git show "${base}:${manifest}" 2>/dev/null | grep -m1 -E '^tag:' | sed 's/^tag: *//')

  if [[ -z "${old}" ]]; then
    echo "ok   ${manifest} is new, nothing to compare"
  elif [[ "${old}" == "${new}" ]]; then
    echo "::error title=Tag did not move::${dir} changed but tag: is still ${new}. The publish job skips tags that already exist, so this change would never reach the registry. Bump the tag, or add [no-publish] to the pull request body if the change cannot affect the built package."
    status=1
  else
    echo "ok   ${dir}: ${old} -> ${new}"
  fi
done

exit ${status}
```

```sh
chmod +x .github/scripts/tag-must-move.sh
```

## 2. New job in `.github/workflows/ci.yml`

Add at the top of `jobs:`:

```yaml
  # The publish job skips a tag that already exists, so a package edited without
  # a tag bump is silently never published. Catch it at review time.
  # INTERIM: delete this job when release-please owns the tag (Phase 2).
  tag-must-move:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request' && !contains(github.event.pull_request.body, '[no-publish]')
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: A changed package must bump its tag
        run: |
          set -uo pipefail
          git fetch -q --depth=1 origin "${{ github.base_ref }}"
          mapfile -t CHANGED < <(git diff --name-only FETCH_HEAD...HEAD)
          bash .github/scripts/tag-must-move.sh FETCH_HEAD "${CHANGED[@]:-}"
```

## Behaviour

| Situation | Result |
|---|---|
| Package changed, tag bumped | ✅ `ok packages/services/trino: 480.0.0-p21 -> 480.0.0-p22` |
| Package changed, tag unchanged | ❌ fails, naming the package and the stale tag |
| Only `README.md` changed | ✅ passes silently |
| New package (no previous tag) | ✅ passes |
| PR body contains `[no-publish]` | ✅ job skipped entirely |

The escape hatch is for changes that genuinely cannot affect the built artifact —
a comment or a description fix. It is deliberately a PR-body marker rather than a
label, so it shows up in review.

## Verified

- `bash -n` passes.
- All four cases above exercised against the real repository.
- Replayed over 40 real commits: 18 caught, 1 of them a `docs:` false positive.
