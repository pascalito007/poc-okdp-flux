# OKDP Decoupling — Task Breakdown

## Phases

| Phase | Besoin                                  | Deliverable                                 | Duration   |
| ----- | --------------------------------------- | ------------------------------------------- | ---------- |
| 1     | [Besoin 1](phase1-besoin1-inventory.md) | Component inventory at OKDP/OKDP repo       | ~2.5 days  |
| 2     | [Besoin 2](phase2-besoin2-handbook.md)  | okdp-handbook: module docs + umbrella chart | ~33 days   |
| 3     | [Besoin 3](phase3-besoin3-fluxcd.md)    | FluxCD-native sandbox refactor              | ~19.5 days |

## Governance

- Each PR requires 2 validators (1 technical + 1 clarity)
- Both validators must test `helm install` commands on a clean cluster
- See [GOVERNANCE.md](../okdp-root-repo/GOVERNANCE.md) for full governance model
