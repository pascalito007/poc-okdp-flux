# Spark Images Issues

---

## Issue S.0

**Title**: [spark-images] Document standalone build procedure for each image type

**Labels**: `documentation`, `besoin-1`

**Body**:

### Description

Document how to build each Spark image type independently, following official Apache Spark
build procedures. Users should be able to build any image without relying on the OKDP CI pipeline.

Currently, the build process is tightly coupled to the GitHub Actions CI — there's no documented
way to build a single image locally or with custom parameters.

### Deliverables

- [ ] Document official Apache Spark image build procedure (from source or distribution)
- [ ] Document how to build `spark-base` locally with custom Spark/Java/Scala versions
- [ ] Document how to build `spark` (with OKDP auth filter) locally
- [ ] Document how to build `spark-py` locally with custom Python version
- [ ] Document how to build `spark-r` locally
- [ ] Document the OKDP extension layer (auth filter JAR) as an optional add-on
- [ ] Provide a local build script or Makefile for single-image builds

### Acceptance Criteria

- [ ] A user can build any image type locally without the CI pipeline
- [ ] A user can build with a custom Spark/Java/Python version not in the matrix
- [ ] The OKDP extensions are clearly separated from the base Spark build
- [ ] Validated by technical validator
- [ ] Validated by clarity validator

**Effort**: 3 days

---

## Issue S.1

**Title**: [spark-images] Add workflow_dispatch for ad-hoc single-version builds

**Labels**: `besoin-1`, `infrastructure`

**Body**:

### Description

The current CI builds the full version matrix on every release. For security response scenarios,
we need the ability to rebuild a single specific image with custom parameters.

### Use Case

Security team reports CVE in a dependency. We need to:

1. Rebuild Spark 3.5.6 with a patched library version
2. Test the fix
3. Push the patched image

Currently this requires a full matrix build or manual intervention.

### Deliverables

- [ ] Add `workflow_dispatch` trigger with input parameters:
  - `spark_version` (required)
  - `java_version` (required)
  - `scala_version` (required)
  - `python_version` (optional, for spark-py)
  - `image_type` (spark-base, spark, spark-py, spark-r)
  - `publish` (true/false)
- [ ] The workflow builds only the specified image, not the full matrix
- [ ] Document the ad-hoc build procedure

### Acceptance Criteria

- [ ] Can trigger a single-image build from GitHub Actions UI
- [ ] Can specify custom version parameters
- [ ] Build completes without building the full matrix

**Effort**: 2 days

---

## Issue S.2

**Title**: [spark-images] Document the pombump security patching process

**Labels**: `documentation`, `besoin-1`

**Body**:

### Description

The pombump system for security patching is powerful but not well documented for contributors
who need to add new patches or update dependency versions.

### Deliverables

- [ ] Document how to add a new security patch for a specific Spark version
- [ ] Document how to update a Maven dependency version via pombump
- [ ] Document the patch file format and naming convention
- [ ] Document the pre-build-patch-pombump.yml configuration
- [ ] Provide a step-by-step guide for the security response workflow:
  1. CVE reported
  2. Identify affected Spark versions
  3. Create/update patch or pombump config
  4. Test locally
  5. PR → CI → Release

### Acceptance Criteria

- [ ] A contributor can add a new security patch by following the documentation
- [ ] The security response workflow is clear and actionable
- [ ] Validated by technical validator
- [ ] Validated by clarity validator

**Effort**: 2 days

---

## Issue S.3

**Title**: [spark-images] Audit and complete existing documentation

**Labels**: `documentation`, `besoin-1`

**Body**:

### Description

The existing README.md is good but needs review for completeness and accuracy.

### Checklist

- [ ] README.md: verify image hierarchy diagram is up to date
- [ ] README.md: verify tagging convention matches actual published tags
- [ ] README.md: add "consumer guide" section (which image for which use case)
- [ ] PATCH-POMBUMP.md: verify accuracy against current implementation
- [ ] CHANGELOG.md: verify it's up to date
- [ ] Verify all version references match `.build/reference-versions.yml`
- [ ] Validated by technical validator
- [ ] Validated by clarity validator

**Effort**: 1 day
