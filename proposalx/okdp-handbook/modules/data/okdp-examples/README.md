# OKDP Examples

## Overview

A collection of hands-on examples, helper utilities, Jupyter notebooks, and data workflows
that showcase how to work with the OKDP Platform.

## Upstream Project

- **Project**: [OKDP/okdp-examples](https://github.com/OKDP/okdp-examples)
- **Helm Chart**: OCI artifact `oci://quay.io/okdp/charts/okdp-examples`
- **Chart Version**: 1.1.0
- **App Version**: 1.0.0

## What This Module Provides in OKDP

- Automated dataset download and upload to S3 (NYC taxi data)
- Trino SQL examples for creating external tables
- Jupyter notebooks for interactive data analysis
- End-to-end data pipeline demonstrations

## Key Configuration Areas

- **S3**: endpoint, bucket, prefix for dataset storage
- **Trino**: endpoint for SQL queries
- **Spark**: event log directory
- **Proxy**: optional HTTP/HTTPS proxy for dataset downloads
