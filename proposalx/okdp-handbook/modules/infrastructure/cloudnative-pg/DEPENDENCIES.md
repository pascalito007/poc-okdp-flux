# CloudNativePG Dependencies

## Required Before Installation

None — CloudNativePG is an infrastructure prerequisite.

## Required By (Downstream Dependents)

All OKDP modules that need a PostgreSQL database:

- [keycloak](../keycloak/) — identity provider metadata
- [hive-metastore](../../data/hive-metastore/) — table/partition metadata
- [superset](../../data/superset/) — dashboard metadata and user data
- [airflow](../../data/airflow/) — DAG metadata and task state
- [seaweedfs](../seaweedfs/) — filer metadata (optional)

## Database Endpoint

All downstream modules connect to:

```
Host: postgresql-instance-rw.cnpg-system.svc.cluster.local
Port: 5432
```
