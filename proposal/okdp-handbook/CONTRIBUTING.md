# Contributing to OKDP Handbook

## Documentation Standards

Each module must include the following files:

```
modules/<category>/<module-name>/
├── README.md          # Overview, purpose, links to upstream project
├── INSTALL.md         # Step-by-step installation with real helm commands
├── DEPENDENCIES.md    # Prerequisites and inter-module dependencies
└── values/
    ├── sandbox.yaml   # Values for OKDP sandbox environment
    └── production.yaml # Values template for production environments
```

## README.md Template

```markdown
# <Module Name>

## Overview

One paragraph describing what this module does and why it's part of OKDP.

## Upstream Project

- **Project**: [link to upstream]
- **Helm Chart**: [link to chart]
- **Chart Version**: X.Y.Z
- **App Version**: X.Y.Z

## What This Module Provides in OKDP

Describe the specific role this module plays in the OKDP platform.

## Key Configuration Areas

List the main configuration areas (auth, storage, networking, etc.)
```

## INSTALL.md Template

```markdown
# Installing <Module Name>

## Prerequisites

Checklist with links to dependency INSTALL.md files.

## Add Helm Repository

Exact helm repo add commands.

## Install

Exact helm install commands with values file references.

## Verify

kubectl commands to verify the installation.

## Post-Installation Steps

Any manual steps needed after helm install.

## Uninstall

Exact helm uninstall commands.
```

## Review Process

1. Author creates a PR with the module documentation
2. Two validators must approve:
   - **Technical validator**: someone who knows the module
   - **Clarity validator**: someone who does NOT know the module (validates readability)
3. Both validators must successfully run the `helm install` commands on a clean cluster
4. PR is merged after both approvals

## Quality Checklist

Before submitting a PR, verify:

- [ ] All `helm install` commands work on a clean Kind cluster
- [ ] All prerequisites are documented with links
- [ ] Values files contain real, working values (not placeholders)
- [ ] Secrets and credentials are documented (what's needed, not actual values)
- [ ] Verification commands produce the expected output
- [ ] Uninstall procedure is clean (no orphaned resources)
