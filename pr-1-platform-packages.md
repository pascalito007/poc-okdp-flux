# PR 1 — `OKDP/platform-packages`

> Org PR template: [`OKDP/.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/OKDP/.github/blob/main/PULL_REQUEST_TEMPLATE.md)
> **MERGED** as #67 on 28 Aug 12:27 UTC. Kept for the record; the `tag-must-move`
> addendum went in with it.
> Branch: `chore/publish-guardrails`, one commit on top of `f2a6c08`.
> Patch: `phase1-platform-packages.patch` (git-am format) / `phase1-platform-packages.diff`.

### Title

```
ci: publish on release only and never overwrite a published tag
```

### Body

```markdown
## Description

Merging to main published **every** package to `quay.io` under the tag written by
hand in its manifest, and nothing checked whether that tag already existed. A merge
that did not bump `-pNN` silently replaced the published artifact.

Measured against the quay.io tag API (which records a revision each time a tag is
repointed), across this repo and `sandbox-dependencies`:

- **50 of the 59 published tags have carried more than one artifact**, for a total
  of **201 silent replacements**.
- `spark-defaults:1.0.0-p01` has **17 distinct digests**. That package has exactly
  one commit in this repository — it was never edited. It is republished on every
  merge because the build loop takes every manifest under `packages/`, and the
  build is not reproducible, so an untouched package still produces a new digest.
- `trino:480.0.0-p07` was rewritten on 21 Aug with content two weeks newer than the
  version that tag originally named, after `p20` had already shipped.

So this is not only "someone forgot to bump the tag" — an untouched package is
overwritten too, and no amount of discipline prevents that.

Three changes:

**1. `publish-on-merge.yml` is deleted.** `quay.io` is no longer written on merge.
`publish.yml` keeps its `workflow_dispatch` trigger, and `release-please.yml` keeps
its call, so publishing is now something a person or a release asks for.

**2. A published tag is immutable.** Before building, each package's `name` and
`tag` are read from its manifest and checked against the registry with
`oras manifest fetch`. Anything already published is dropped from the build list
and reported, the way `helm-charts-utilities` skips a chart version that exists.
The new `on_existing_tag` input turns that skip into a hard error (`fail`) — the
mode the release path will use, where a freshly minted version already existing
means a real bug.

This also gives "publish only what changed" for free: an unchanged package has an
unchanged tag, so it is already published, so it is skipped. No diff logic needed.

The CI registry is deliberately **exempt** — `ghcr.io` is a scratch area and a pull
request must keep getting its validation build, so it always rebuilds.

**3. One broken package no longer stops the other twelve.** The loop collects
failures and reports them together instead of aborting on the first one. That was
the second half of #56.

### What changes for the team

Merging a package fix no longer publishes it. To ship, dispatch `publish.yml`
(Actions → publish → Run workflow) after the merge. This is an interim step: #NN
tracks moving to per-package release-please so that a release, not a dispatch, is
what publishes.

## Related Issue

Fixes #56

## Type of Change

- [x] Bug fix
- [ ] New feature
- [ ] Documentation update
- [x] Refactor / chore
- [ ] Breaking change

## How to Test

**1. The guard skips what is already published.** With this branch checked out,
run the guard's logic against the live registry:

```sh
KUBOCD_PACKAGES=$(find packages -type f \( -name "*.yaml" -o -name "*.yml" \) \
  -exec grep -l '^modules:' {} \; | tr '\n' ' ')

for package in ${KUBOCD_PACKAGES}; do
  name=$(yq -e -r '.name' "$package"); tag=$(yq -e -r '.tag' "$package")
  n=$(curl -s "https://quay.io/api/v1/repository/okdp/platform-packages%2F${name}/tag/?specificTag=${tag}&onlyActiveTags=true" \
      | jq '.tags | length')
  [ "$n" -gt 0 ] && echo "SKIP  $name:$tag" || echo "BUILD $name:$tag"
done
```

Every package prints `SKIP` today. Before this PR, dispatching `publish.yml` would
have re-pushed all thirteen over themselves.

**2. Only a bumped package is published.** Bump one `tag:`, dispatch `publish.yml`,
and check the job summary: a "Package publication plan" table listing twelve
`skipped, already published` and one `build and push`.

**3. A pull request still gets a full build.** Open any PR — `ci` builds all
thirteen packages to `ghcr.io` exactly as before. The guard does not apply there.

**4. The strict mode errors.** Call the template with `on_existing_tag: fail` and
no version bump; the job fails with
`::error title=Tag already published::` naming every offending `name:tag`.

## Checklist

- [x] I have tested my changes
- [ ] Documentation updated if needed
- [ ] If breaking change: migration path described above
- [x] I hereby declare this contribution to be licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
- [x] I hereby agree to grant [TOSIT](https://www.tosit.io/) a copyright license to use my contributions.
```

---

## Making the changes by hand

Five edits. Nothing else in the repository is touched.

### 1. Delete a file

```sh
git rm .github/workflows/publish-on-merge.yml
```

That is the whole of change 1 — `quay.io` stops being written on merge.

The remaining four are all in `.github/workflows/kubocd-package-template.yml`.

### 2. Add the `on_existing_tag` input

In the `on: workflow_call: inputs:` block, find the end of `oci_package_prefix`
and insert **before** `runs-on:`:

```yaml
      oci_package_prefix:
        description: "OCI package prefix, e.g., 'quay.io/my-org/<PACKAGE-PREFIX>', i.e.: <PACKAGE-PREFIX> = platform-packages"
        required: true
        type: string
                                          # <-- insert the block below here
      runs-on:
```

Insert:

```yaml
      on_existing_tag:
        description: >-
          What to do when a package tag already exists on the target registry.
          "skip" leaves the published artifact alone and builds the rest;
          "fail" stops the job. A published tag is immutable either way.
        required: false
        type: string
        default: "skip"
```

### 3. Install `yq` and `oras`

Find the end of the `Install KuboCD CLI` step:

```yaml
          # Verify installation
          kubocd version
                                          # <-- insert the block below here
      # Build and push packages
      - name: Find KuboCD packages 🔎
```

Insert:

```yaml
      - name: Install yq 🛠️
        uses: mikefarah/yq@v4.45.1

      # oras reads the credentials docker/login-action already wrote to
      # ~/.docker/config.json, so no second login is needed.
      - name: Install oras 🛠️
        uses: oras-project/setup-oras@v1
```

### 4. Add the guard

Find the end of the `Find KuboCD packages` step:

```yaml
      - name: Find KuboCD packages 🔎
        run: |
          KUBOCD_PACKAGES=$(find packages -type f \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l '^modules:' {} \; | tr '\n' ' ')
          echo "KUBOCD_PACKAGES=$KUBOCD_PACKAGES" >> $GITHUB_ENV
                                          # <-- insert the block below here
      - name: Build and push KuboCD packages into CI registry ...
```

Insert:

```yaml
      # A published tag is immutable: the same reference must always resolve to
      # the same artifact. Anything already on the registry is dropped from the
      # build list here, before it can be rebuilt and pushed over itself.
      # Only the public registry is immutable. The CI registry is a scratch
      # area: it must always rebuild, otherwise a PR gets no validation.
      - name: Drop packages already published under their tag 🔒
        if: inputs.publish_to_registry == 'true'
        run: |
          set -uo pipefail

          KEEP=""
          SKIPPED=""

          for package in ${KUBOCD_PACKAGES}
          do
            name=$(yq -e -r '.name' "${package}")
            tag=$(yq  -e -r '.tag'  "${package}")
            ref="${OCI_REPO_PREFIX}/${name}:${tag}"

            if oras manifest fetch --descriptor "${ref}" >/dev/null 2>&1; then
              echo "::notice title=Already published::${ref} exists, skipping ${package}"
              SKIPPED="${SKIPPED} ${name}:${tag}"
            else
              echo "${ref} is free ✓"
              KEEP="${KEEP} ${package}"
            fi
          done

          if [[ -n "${SKIPPED}" && "${{ inputs.on_existing_tag }}" == "fail" ]]; then
            echo "::error title=Tag already published::${SKIPPED# } already exist(s) on ${REGISTRY}. Bump the package version."
            exit 1
          fi

          echo "KUBOCD_PACKAGES=${KEEP# }" >> $GITHUB_ENV
          {
            echo "### Package publication plan"
            echo ""
            echo "| Package | Action |"
            echo "| --- | --- |"
            for s in ${SKIPPED}; do echo "| \`${s}\` | skipped, already published |"; done
            for p in ${KEEP};    do echo "| \`${p}\` | build and push |"; done
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Nothing left to publish ✅
        if: inputs.publish_to_registry == 'true' && env.KUBOCD_PACKAGES == ''
        run: echo "Every package is already published under its current tag. Nothing to do."
```

### 5. Make the two build steps skippable and resilient

Both build steps change the same way. **CI registry step** — the `if:` gains a
condition, and the loop stops aborting on the first failure:

```yaml
      - name: Build and push KuboCD packages into CI registry (${{ inputs.ci_registry }}) 📦
        if: inputs.publish_to_registry == 'false' && env.KUBOCD_PACKAGES != ''
        run: |
          set -uo pipefail
          FAILED=""

          for package in ${KUBOCD_PACKAGES}
          do
             echo "::group::kubocd package ${package}"
             echo "kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX"
             # One broken package must not stop the others: collect the failures
             # and report them all at the end.
             kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX || FAILED="${FAILED} ${package}"
             echo "::endgroup::"
          done

          if [[ -n "${FAILED}" ]]; then
            echo "::error title=Package build failed::${FAILED# }"
            exit 1
          fi
        env:
          KCD_OCI_GHCR_IO_USER: ${{ github.actor }}
          KCD_OCI_GHCR_IO_SECRET: ${{ github.token }}
```

**Public registry step** — identical, with `'true'` and the quay credentials:

```yaml
      - name: Build and push KuboCD packages into public registry (${{ inputs.registry }}) 📦
        if: inputs.publish_to_registry == 'true' && env.KUBOCD_PACKAGES != ''
        run: |
          set -uo pipefail
          FAILED=""

          for package in ${KUBOCD_PACKAGES}
          do
             echo "::group::kubocd package ${package}"
             echo "kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX"
             # One broken package must not stop the others: collect the failures
             # and report them all at the end.
             kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX || FAILED="${FAILED} ${package}"
             echo "::endgroup::"
          done

          if [[ -n "${FAILED}" ]]; then
            echo "::error title=Package publication failed::${FAILED# }"
            exit 1
          fi
        env:
          KCD_OCI_QUAY_IO_USER: ${{ secrets.REGISTRY_USERNAME }}
          KCD_OCI_QUAY_IO_SECRET: ${{ secrets.REGISTRY_ROBOT_TOKEN }}
```

### Check your work

```sh
python3 -c "import yaml;yaml.safe_load(open('.github/workflows/kubocd-package-template.yml'));print('yaml ok')"
git diff --stat     # expect: template +95/-4, publish-on-merge.yml deleted
```

### Commit

```
ci: publish on release only and never overwrite a published tag
```

---

## If in doubt: the complete file

Replacing `.github/workflows/kubocd-package-template.yml` with this is equivalent
to steps 2–5.

```yaml
#
# Copyright 2025 The OKDP Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name: Build and push KuboCD packages

on:
  workflow_call:
    inputs:
      publish_to_registry:
        description: Wheter to push to the registry
        required: false
        type: string
        default: "false"
      registry:
        description: The container registry
        required: true
        type: string
      ci_registry:
        description: "The registry used to push ci images"
        required: false
        type: string
        default: "ghcr.io"
      oci_package_prefix:
        description: "OCI package prefix, e.g., 'quay.io/my-org/<PACKAGE-PREFIX>', i.e.: <PACKAGE-PREFIX> = platform-packages"
        required: true
        type: string
      on_existing_tag:
        description: >-
          What to do when a package tag already exists on the target registry.
          "skip" leaves the published artifact alone and builds the rest;
          "fail" stops the job. A published tag is immutable either way.
        required: false
        type: string
        default: "skip"
      runs-on:
        description: GitHub Actions Runner image
        required: true
        type: string

defaults:
  run:
    shell: bash

jobs:

  kubocd-package:
    runs-on: ${{ inputs.runs-on }}
    steps:

      - name: Checkout Repo ⚡️
        uses: actions/checkout@v4

      - name: Login to the CI registry (${{ inputs.ci_registry }}) 🔐
        if: inputs.publish_to_registry == 'false'
        uses: docker/login-action@v3
        with:
          registry: ${{ inputs.ci_registry }}
          username: ${{ github.actor }}
          password: ${{ github.token }}

      - name: Login into public registry (${{ inputs.registry }}) 🔐
        if: inputs.publish_to_registry == 'true'
        uses: docker/login-action@v3
        with:
          registry: ${{ inputs.registry }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_ROBOT_TOKEN }}

      - name: Set CI Github container registry namespace (${{ inputs.ci_registry }}) 📦
        if: inputs.publish_to_registry == 'false'
        run:  |
          echo "OWNER=${GITHUB_REPOSITORY_OWNER@L}" >> $GITHUB_ENV
          echo "REGISTRY=${{ inputs.ci_registry }}" >> $GITHUB_ENV
          echo "OCI_REPO_PREFIX=${{ inputs.ci_registry }}/${GITHUB_REPOSITORY@L}/${{ inputs.oci_package_prefix }}" >> $GITHUB_ENV
        shell: bash

      - name: Set public container registry namespace (${{ inputs.registry }}) 📦
        if: inputs.publish_to_registry == 'true'
        run:  |
          echo "OWNER=${GITHUB_REPOSITORY_OWNER@L}" >> $GITHUB_ENV
          echo "REGISTRY=${{ inputs.registry }}" >> $GITHUB_ENV
          echo "OCI_REPO_PREFIX=${{ inputs.registry }}/${GITHUB_REPOSITORY_OWNER@L}/${{ inputs.oci_package_prefix }}" >> $GITHUB_ENV
        shell: bash

      - name: Install KuboCD CLI 🛠️
        run: |
          # v0.3.2 is the first release whose deserializer understands the
          # Contract schema grammar (contract:, connectionRef, outputs).
          curl -L -o kubocd https://github.com/kubocd/kubocd/releases/download/v0.3.2/kubocd_Linux_x86_64

          # Make it executable
          chmod +x kubocd

          # Move to /usr/local/bin
          sudo mv kubocd /usr/local/bin/

          # Verify installation
          kubocd version

      - name: Install yq 🛠️
        uses: mikefarah/yq@v4.45.1

      # oras reads the credentials docker/login-action already wrote to
      # ~/.docker/config.json, so no second login is needed.
      - name: Install oras 🛠️
        uses: oras-project/setup-oras@v1

      # Build and push packages
      - name: Find KuboCD packages 🔎
        run: |
          KUBOCD_PACKAGES=$(find packages -type f \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l '^modules:' {} \; | tr '\n' ' ')
          echo "KUBOCD_PACKAGES=$KUBOCD_PACKAGES" >> $GITHUB_ENV

      # A published tag is immutable: the same reference must always resolve to
      # the same artifact. Anything already on the registry is dropped from the
      # build list here, before it can be rebuilt and pushed over itself.
      # Only the public registry is immutable. The CI registry is a scratch
      # area: it must always rebuild, otherwise a PR gets no validation.
      - name: Drop packages already published under their tag 🔒
        if: inputs.publish_to_registry == 'true'
        run: |
          set -uo pipefail

          KEEP=""
          SKIPPED=""

          for package in ${KUBOCD_PACKAGES}
          do
            name=$(yq -e -r '.name' "${package}")
            tag=$(yq  -e -r '.tag'  "${package}")
            ref="${OCI_REPO_PREFIX}/${name}:${tag}"

            if oras manifest fetch --descriptor "${ref}" >/dev/null 2>&1; then
              echo "::notice title=Already published::${ref} exists, skipping ${package}"
              SKIPPED="${SKIPPED} ${name}:${tag}"
            else
              echo "${ref} is free ✓"
              KEEP="${KEEP} ${package}"
            fi
          done

          if [[ -n "${SKIPPED}" && "${{ inputs.on_existing_tag }}" == "fail" ]]; then
            echo "::error title=Tag already published::${SKIPPED# } already exist(s) on ${REGISTRY}. Bump the package version."
            exit 1
          fi

          echo "KUBOCD_PACKAGES=${KEEP# }" >> $GITHUB_ENV
          {
            echo "### Package publication plan"
            echo ""
            echo "| Package | Action |"
            echo "| --- | --- |"
            for s in ${SKIPPED}; do echo "| \`${s}\` | skipped, already published |"; done
            for p in ${KEEP};    do echo "| \`${p}\` | build and push |"; done
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Nothing left to publish ✅
        if: inputs.publish_to_registry == 'true' && env.KUBOCD_PACKAGES == ''
        run: echo "Every package is already published under its current tag. Nothing to do."

      - name: Build and push KuboCD packages into CI registry (${{ inputs.ci_registry }}) 📦
        if: inputs.publish_to_registry == 'false' && env.KUBOCD_PACKAGES != ''
        run: |
          set -uo pipefail
          FAILED=""

          for package in ${KUBOCD_PACKAGES}
          do
             echo "::group::kubocd package ${package}"
             echo "kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX"
             # One broken package must not stop the others: collect the failures
             # and report them all at the end.
             kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX || FAILED="${FAILED} ${package}"
             echo "::endgroup::"
          done

          if [[ -n "${FAILED}" ]]; then
            echo "::error title=Package build failed::${FAILED# }"
            exit 1
          fi
        env:
          KCD_OCI_GHCR_IO_USER: ${{ github.actor }}
          KCD_OCI_GHCR_IO_SECRET: ${{ github.token }}

      - name: Build and push KuboCD packages into public registry (${{ inputs.registry }}) 📦
        if: inputs.publish_to_registry == 'true' && env.KUBOCD_PACKAGES != ''
        run: |
          set -uo pipefail
          FAILED=""

          for package in ${KUBOCD_PACKAGES}
          do
             echo "::group::kubocd package ${package}"
             echo "kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX"
             # One broken package must not stop the others: collect the failures
             # and report them all at the end.
             kubocd package ${package} --ociRepoPrefix $OCI_REPO_PREFIX || FAILED="${FAILED} ${package}"
             echo "::endgroup::"
          done

          if [[ -n "${FAILED}" ]]; then
            echo "::error title=Package publication failed::${FAILED# }"
            exit 1
          fi
        env:
          KCD_OCI_QUAY_IO_USER: ${{ secrets.REGISTRY_USERNAME }}
          KCD_OCI_QUAY_IO_SECRET: ${{ secrets.REGISTRY_ROBOT_TOKEN }}
```
