# Contributing to OKDP

Thank you for your interest in contributing to OKDP!

## How to Contribute

### Reporting Issues

- Use GitHub Issues on the relevant repository
- Use the provided issue templates (bug report, feature request)
- For security vulnerabilities, see [SECURITY.md](SECURITY.md)

### Contributing Documentation

Module documentation and install guides live in the
[okdp-handbook](https://github.com/OKDP/okdp-handbook) repository.

See the [okdp-handbook CONTRIBUTING.md](https://github.com/OKDP/okdp-handbook/blob/main/CONTRIBUTING.md)
for documentation standards, templates, and review process.

### Contributing Code

1. Fork the relevant repository
2. Create a feature branch from `main`
3. Make your changes
4. Ensure CI passes (lint, tests, build)
5. Submit a Pull Request

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add OIDC support for Trino
fix: correct S3 endpoint in hive-metastore values
docs: update airflow INSTALL.md with gitSync config
chore: bump cert-manager to v1.17.1
```

### Pull Request Process

- PRs require at least 1 maintainer approval
- Documentation PRs (okdp-handbook) require 2 approvals (1 technical + 1 clarity)
- All CI checks must pass
- Keep PRs focused — one change per PR

## Repository Map

| Repository                                                  | What to Contribute                             |
| ----------------------------------------------------------- | ---------------------------------------------- |
| [OKDP/OKDP](https://github.com/OKDP/OKDP)                   | Project-level docs, governance, roadmap        |
| [OKDP/okdp-handbook](https://github.com/OKDP/okdp-handbook) | Module docs, install guides, Helm values       |
| [OKDP/okdp-sandbox](https://github.com/OKDP/okdp-sandbox)   | Sandbox environment                            |
| OKDP/hive-metastore, spark-history-server, etc.             | Module source code, Helm charts, Docker images |

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
