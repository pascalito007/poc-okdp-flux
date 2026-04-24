# OKDP Project Governance

## Overview

OKDP (Open Kubernetes Data Platform) is an open-source project governed by a community of contributors
from multiple organizations. This document defines the roles, responsibilities, and decision-making
processes for the project.

## Roles

### Contributor

Anyone who contributes to the project via pull requests, issues, documentation, or reviews.

- Can submit PRs to any OKDP repository
- Can participate in discussions and reviews
- No special permissions required

### Maintainer

Trusted contributors with write access to one or more OKDP repositories.

- Can merge PRs after required approvals
- Can manage issues and labels
- Can release new versions
- Must follow the review process (no self-merging)

### Technical Lead

Maintainers who guide the technical direction of the project.

- Define architecture decisions
- Approve or reject significant design changes
- Resolve technical disagreements
- Ensure consistency across repositories

### Project Lead

Overall project governance and coordination.

- Define project roadmap and priorities
- Coordinate between organizations
- Represent the project externally
- Final decision authority on governance matters

## Decision Making

### Technical Decisions

- **Minor changes** (bug fixes, doc updates): 1 maintainer approval
- **Module documentation** (okdp-handbook): 2 approvals (1 technical + 1 clarity validator)
- **Architecture changes**: Technical Lead approval required
- **New components**: Discussion in a dedicated issue, Technical Lead approval

### Governance Decisions

- Discussed openly in GitHub issues or dedicated meetings
- Require consensus among Technical Leads
- Project Lead has final authority if consensus cannot be reached

## Contribution Process

### For Documentation (okdp-handbook)

1. Pick a task from the [task breakdown](https://github.com/OKDP/okdp-handbook/tree/main/roadmap/)
2. Create a branch and submit a PR
3. Two validators must approve:
   - **Technical validator**: verifies correctness (values work, commands are accurate)
   - **Clarity validator**: verifies readability (someone unfamiliar can follow the guide)
4. Both validators must test the `helm install` commands on a clean cluster
5. PR is merged after both approvals

### For Code Changes (module repos)

1. Create an issue describing the change
2. Submit a PR referencing the issue
3. At least 1 maintainer must approve
4. CI must pass (lint, tests, build)
5. PR is merged after approval

### For Architecture Changes

1. Create a discussion issue with the proposal
2. Present in a team meeting if significant
3. Technical Lead reviews and approves
4. Implementation follows the standard PR process

## Repository Structure

| Repository                                                  | Purpose                                       | Maintainers        |
| ----------------------------------------------------------- | --------------------------------------------- | ------------------ |
| [OKDP/OKDP](https://github.com/OKDP/OKDP)                   | Project root, component inventory, governance | Project Lead       |
| [OKDP/okdp-handbook](https://github.com/OKDP/okdp-handbook) | Module docs, install guides, values           | All maintainers    |
| [OKDP/okdp-sandbox](https://github.com/OKDP/okdp-sandbox)   | Sandbox environment (FluxCD)                  | All maintainers    |
| OKDP/hive-metastore, spark-history-server, etc.             | Individual module repos                       | Module maintainers |

## Communication

- **GitHub Issues**: primary channel for technical discussions
- **Pull Requests**: code and documentation review
- **Meetings**: regular sync meetings for roadmap and architecture decisions

## Code of Conduct

All participants are expected to follow professional and respectful communication standards.
Technical disagreements are resolved through discussion, evidence, and consensus — not authority.

## Amendments

This governance document can be amended through a PR to the `OKDP/OKDP` repository,
requiring approval from the Project Lead and at least one Technical Lead.
