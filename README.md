# Netra

Netra is our self-hosted observability stack. This repo manages one shared
observability setup that tracks all environments (dev, stage, prod) through
labels, namespaces, and dashboard variables.

## What this repo is

A scaffold for the Netra observability platform built on Grafana OSS,
kube-prometheus-stack, Loki, Alloy, Tempo, OpenTelemetry Collector, and
blackbox_exporter. All dashboards, alerts, datasources, and runbooks are
versioned in Git.

## What this repo is not

- Not application instrumentation. Services adopt the published contract
  (`docs/app-integration.md`); their wiring lives in their own repos, not here.
- Not a Datadog replacement yet. Datadog stays running during validation.
  See `docs/datadog-migration.md`.
- Not a long-term storage tier. No Thanos, Mimir, OpenSearch, Elasticsearch,
  or warehouse archival.

## Install

```sh
./scripts/install.sh
```

This adds Helm repos, creates the `observability` namespace, and installs
pinned chart releases (May 2026): kube-prometheus-stack **86.1.0**, Loki
**17.1.5** and Tempo **2.2.0** from `grafana-community`, Alloy **1.8.2**,
OpenTelemetry Collector **0.158.0**, blackbox_exporter **11.9.1** — then
applies manifests.

## Verify

```sh
./scripts/verify.sh
./scripts/validate.sh
```

`verify.sh` checks live cluster state. `validate.sh` lints local YAML/JSON
without needing a cluster.

## Required placeholders

Before installing into a real cluster, replace these placeholders. Search the
repo for `REPLACE_ME_`:

- `REPLACE_ME_LOKI_GCS_BUCKET`, `REPLACE_ME_TEMPO_GCS_BUCKET` (GCS buckets)
- `REPLACE_ME_LOKI_GCP_SERVICE_ACCOUNT`,
  `REPLACE_ME_TEMPO_GCP_SERVICE_ACCOUNT` (GSA emails bound to the Loki/Tempo
  KSAs via GKE Workload Identity; each needs `roles/storage.objectAdmin` on
  its bucket)
- `REPLACE_ME_SSD_STORAGECLASS` (SSD-backed StorageClass for WAL/cache PVCs)
- `REPLACE_ME_GRAFANA_ADMIN_PASSWORD` (use a sealed secret or external
  secret manager; do not commit)
- `REPLACE_ME_CLUSTER_NAME`
- Blackbox probe targets in `manifests/blackbox/probes-configmap.yaml`

## Retention (default)

| Signal     | Default | Notes                                            |
| ---------- | ------- | ------------------------------------------------ |
| Metrics    | 15d     | Prometheus PVC                                   |
| Logs       | 15d     | Loki on object storage                           |
| Traces     | 7d      | Tempo on object storage, configurable up to 15d  |
| RUM        | 7-15d   | Stored in Loki and Tempo                         |
| Dashboards | forever | Git                                              |
| Alerts     | forever | Git                                              |
| Runbooks   | forever | Git                                              |

Retention is configurable through Helm values.

## Tracking all environments

One stack, all envs. Every metric, log, trace, and RUM event carries:

- `environment` (dev | stage | prod)
- `namespace`
- `service` / `service_name`
- `pod`
- `cluster`
- `team`

Every dashboard exposes `environment` (and `service` where applicable) as
template variables so a single dashboard answers the same question for any env.

## Dashboards and alerts are Git-owned

- Dashboards are JSON files under `dashboards/`, loaded by the Grafana
  sidecar via ConfigMaps.
- Alerts are `PrometheusRule` YAML under
  `manifests/prometheus/prometheusrules/`.
- Datasources are a ConfigMap under `manifests/grafana/`.
- Runbooks are Markdown under `runbooks/`.

Edits made in the Grafana UI are considered temporary unless exported and
committed back. See `docs/dashboards-alerts-in-git.md`.

## Layout

```
values/        Helm values per component
manifests/     Namespace, node scheduling, ServiceMonitors, PrometheusRules
dashboards/    Grafana dashboard JSON (Git-owned)
runbooks/      On-call runbooks (Markdown)
scripts/       install / uninstall / verify / validate / port-forward
docs/          Architecture, migration, integration, checklist
```

## Hard rules

- Do not change app code in this task.
- Do not remove or disable Datadog.
- Do not edit application repos from here — consumers adopt `docs/app-integration.md`.
- Do not hardcode secrets.
- Do not expose Grafana, Prometheus, Loki, Tempo, or Alertmanager publicly
  by default.
- Do not use high-cardinality Loki labels (`request_id`, `trace_id`, etc.).
- Do not use filesystem storage for production Loki/Tempo.
- Do not create separate observability stacks per environment.
