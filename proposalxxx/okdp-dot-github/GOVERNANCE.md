# OKDP Project Governance

## Overview

OKDP (Open Kubernetes Data Platform) is an open-source project governed by a community of contributors
from multiple organizations. It was initiated by **DGFiP** and **Orange** and is supported by
[TOSIT](https://tosit.fr) (The Open Source I Trust), an association that promotes sovereign and
open-source technology adoption.

This document defines the roles, responsibilities, and decision-making processes for the project.

## Values

OKDP and its community embrace the following values:

- **Openness**: All work (decisions, discussions, roadmap, and design) happens in public GitHub
  repositories and meetings. Communication is discoverable and accessible to anyone.

- **Sovereignty**: OKDP is independent of any single organization or institution. No company,
  government body, or sponsor controls the project. Each contributor participates as an individual,
  and leadership reflects the broader community.

- **Merit**: Contributions are evaluated on technical quality and alignment with project goals,
  not on who submits them. Ideas stand on their own.

- **Community over Organizations**: The long-term health and sustainability of the community takes
  priority over any organization's roadmap, deadlines, or goals. Sustaining contributors and
  maintainers matters more than shipping features.

- **Inclusivity**: OKDP welcomes contributors of all backgrounds, employers, and experience levels.
  A respectful and collaborative environment is a prerequisite for good technical work.

## Roles

The current list of Maintainers, Technical Leads, and Project Leads is maintained in
[MAINTAINERS.md](https://github.com/OKDP/OKDP/blob/main/MAINTAINERS.md).

### Contributor

Anyone who engages with the project via pull requests, issues, documentation, or reviews.

- Can submit PRs to any OKDP repository
- Can participate in discussions and reviews
- No special permissions required

Contributions to any OKDP repository count equally: code, documentation, Helm charts,
Docker images, and community work are all valued.

Before any contribution can be merged, the contributor must sign the **OKDP CLA**
(one-time requirement). See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Maintainer

Trusted contributors with write access to one or more OKDP repositories.

- Can merge PRs after required approvals
- Can manage issues and labels
- Can release new versions
- Must follow the review process (no self-merging)
- Participate in governance decisions with a binding vote

Maintainers are expected to participate actively in the project: attending the TOSIT Contributors
Meeting, reviewing pull requests, engaging in technical discussions, and contributing to releases.

#### Becoming a Maintainer

A Contributor may be nominated as a Maintainer by any existing Maintainer. There is no
fixed contribution threshold; what matters is the nominee's demonstrated understanding
of the project, quality of their contributions, and collaborative engagement with the community.

Contributions of all types count: code, documentation, Helm chart improvements, CI/CD,
Docker images, and community support.

**Nomination process:**

1. Any existing Maintainer may nominate a Contributor by raising the proposal at the
   **TOSIT Contributors Meeting**
2. The nomination is discussed and voted on during that meeting
3. The decision requires **unanimous approval** from present Maintainers
4. The decision is recorded in the meeting notes and a PR is opened to add the new
   Maintainer to [MAINTAINERS.md](https://github.com/OKDP/OKDP/blob/main/MAINTAINERS.md)
5. Upon merge, the new Maintainer is granted the necessary GitHub repository permissions

Maintainer nominations are evaluated without regard to employer or organizational affiliation.

#### Stepping Down

A Maintainer may step down at any time by opening a PR to update their status in
[MAINTAINERS.md](https://github.com/OKDP/OKDP/blob/main/MAINTAINERS.md). Stepping-down
Maintainers are moved to Emeritus status and recognized for their contributions.

#### Inactivity and Removal

Maintainers are expected to remain active in the project. When a Maintainer becomes inactive,
another Maintainer will contact them privately to check their availability.
- If unresponsive or unable to return, the matter is raised at the **TOSIT Contributors Meeting**
  and the removal is decided by **unanimous vote** of present Maintainers
- The decision is recorded in the meeting notes and the Maintainer is moved to **Emeritus**
  status via a PR to [MAINTAINERS.md](https://github.com/OKDP/OKDP/blob/main/MAINTAINERS.md)
- A Maintainer may also be removed immediately by a **unanimous vote** at a TOSIT Contributors Meeting for
  reasons including CoC violations or failure to uphold their responsibilities

#### Emeritus Maintainers

Emeritus Maintainers are former Maintainers recognized for their past contributions. They:

- Retain no voting rights or merge permissions
- May be consulted on project matters at any time
- Can be reinstated as active Maintainers by **unanimous vote** at a TOSIT Contributors Meeting if their availability returns

### Technical Lead

Maintainers who guide the technical direction of the project.

- Define architecture decisions
- Approve or reject significant design changes
- Resolve technical disagreements
- Ensure consistency across repositories

Technical Leads are Maintainers first; they are selected from the Maintainer pool by
**unanimous vote** at a TOSIT Contributors Meeting.

### Project Lead

Overall project governance and coordination.

- Define project roadmap and priorities
- Coordinate between organizations and with TOSIT
- Represent the project externally

If consensus cannot be reached among Maintainers or Technical Leads, the decision is escalated
to the **founding organizations (DGFiP and Orange)**, who hold final authority on governance
matters.

The Project Lead is selected from the Maintainer pool by unanimous vote of existing
Maintainers and Technical Leads at a TOSIT Contributors Meeting.

## Decision Making

### Lazy Consensus

The default decision-making mechanism for OKDP is **lazy consensus**: a proposal is considered
approved if no Maintainer raises an explicit objection within **2 business days**. Silence is
implicit agreement. This applies to day-to-day decisions such as bug fixes, minor PRs, and
documentation updates.

Any Maintainer may block a proposal by raising an explicit objection. The objection must be
addressed, either by revising the proposal or by escalating to a TOSIT Contributors Meeting vote.

### TOSIT Contributors Meeting Vote

Significant decisions are presented and voted on at the **TOSIT Contributors Meeting**.
All votes at TOSIT Contributors Meetings require **unanimous approval** from present Maintainers.

The following decisions always require a TOSIT Contributors Meeting vote:

| Decision | Process |
| ------------------------------------------------ | --------------------------------- |
| Feature PRs and documentation PRs | TOSIT Contributors Meeting (unanimous) |
| Release approvals | TOSIT Contributors Meeting (unanimous) |
| Architecture changes | TOSIT Contributors Meeting (unanimous) |
| New repository or archiving a repository | TOSIT Contributors Meeting (unanimous) |
| Adding a new Maintainer | TOSIT Contributors Meeting (unanimous) |
| Removing a Maintainer | TOSIT Contributors Meeting (unanimous) |
| Electing or changing a Technical Lead | TOSIT Contributors Meeting (unanimous) |
| Electing or changing the Project Lead | TOSIT Contributors Meeting (unanimous) |
| Governance amendments | TOSIT Contributors Meeting (unanimous, + PR to `.github`) |

### Escalation

If a TOSIT Contributors Meeting fails to reach unanimous consensus on a decision, the matter is escalated
to the **founding organizations (DGFiP and Orange)**, who hold final authority.

## License

All OKDP repositories are licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Security

Security vulnerabilities are handled by the Maintainers, following the process described in
[SECURITY.md](SECURITY.md).

## Code of Conduct

All participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Violations
are handled as described in that document.

## Amendments

This governance document can be amended through a PR to the [`OKDP/.github`](https://github.com/OKDP/.github)
repository. The PR must be approved by **unanimous vote** at a TOSIT Contributors Meeting before merging.
