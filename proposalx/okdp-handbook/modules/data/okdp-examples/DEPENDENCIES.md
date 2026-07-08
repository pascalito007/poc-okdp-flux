# OKDP Examples Dependencies

## Required Before Installation

- [SeaweedFS](../../infrastructure/seaweedfs/INSTALL.md) — S3 storage for datasets
- [Trino](../trino/INSTALL.md) — SQL query engine for examples

## Secrets Required

| Secret Name         | Namespace | Keys                             | Purpose                           |
| ------------------- | --------- | -------------------------------- | --------------------------------- |
| `creds-examples-s3` | default   | `S3_ACCESS_KEY`, `S3_SECRET_KEY` | S3 credentials for dataset upload |
