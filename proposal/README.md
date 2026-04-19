# OKDP Decoupling Proposal

## Deliverables

```
proposal/
├── okdp-root-repo/            # Besoin 1: Component inventory + governance (for OKDP/OKDP repo)
│   ├── docs/README.md         # Component inventory with links to okdp-handbook
│   └── GOVERNANCE.md          # Project governance, roles, contribution process
├── okdp-handbook/             # Besoin 2: Module docs + values + umbrella chart
│   └── modules/
│       ├── infrastructure/    # Infra docs + okdp-prerequisites umbrella chart
│       └── data/              # Data platform module docs + values
├── okdp-sandbox-fluxcd/       # Besoin 3: FluxCD-native sandbox (replaces KuboCD)
└── task-breakdown/            # Detailed task breakdown for all 3 phases
```

## What Changed (Tech Lead Feedback)

- **Besoin 1** = Component inventory at `OKDP/OKDP` repo root (not in okdp-handbook)
- **Besoin 2** = Module documentation + values in `okdp-handbook` (not stack scripts)
- **Stack scripts removed** — replaced by infrastructure umbrella chart (meta chart)
- **Governance added** — GOVERNANCE.md for the OKDP project
