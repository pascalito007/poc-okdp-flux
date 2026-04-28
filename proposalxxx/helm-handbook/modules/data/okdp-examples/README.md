# OKDP Examples — OKDP Integration

## What's OKDP-specific in the values

The [sandbox.yaml](values/sandbox.yaml) configures OKDP Examples:

- **S3**: uploads datasets to SeaweedFS via `creds-examples-s3`
- **Trino**: connects to `trino-default.okdp.sandbox` for SQL examples
- **Dataset**: NYC taxi data from public source

## Prerequisites (from OKDP infrastructure)

- SeaweedFS accessible
- Trino running
- Secret: `creds-examples-s3`

## Official docs

- [OKDP Examples](https://github.com/OKDP/okdp-examples)
