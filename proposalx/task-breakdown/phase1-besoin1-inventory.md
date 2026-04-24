# Phase 1 — Besoin 1: Component Inventory (OKDP/OKDP repo)

## Objective

Create a comprehensive component inventory at the root of the `OKDP/OKDP` repository
that serves as the entry point for anyone discovering OKDP. Each component links to its
detailed install guide in `okdp-handbook`.

## Tasks

### Task 1.0: Update OKDP/OKDP repo README and docs

**What**: Create/update the README.md and docs/ in the OKDP root repo with the component
inventory table, links to okdp-handbook, governance doc, and roadmap.

**Deliverables**:

- `README.md` — project overview with component inventory tables
- `docs/README.md` — besoins overview (already exists on docs/okdp-besoins branch)
- `GOVERNANCE.md` — project governance, roles, contribution process
- `CONTRIBUTING.md` — links to okdp-handbook CONTRIBUTING.md

**Acceptance Criteria**:

- Every OKDP component is listed with description, chart source, repo link, and install guide link
- All install guide links point to valid okdp-handbook paths
- Governance document defines roles, review process, and decision making

**Estimated effort**: 2 days

### Task 1.1: Merge docs/okdp-besoins branch

**What**: The besoins documentation already exists on the `docs/okdp-besoins` branch.
Merge it into `main` and ensure it's linked from the root README.

**Estimated effort**: 0.5 day
