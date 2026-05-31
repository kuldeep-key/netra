# Production checklist

Use this before installing Netra into a real cluster, especially prod.
Anything not checked here is a known gap.

## Before install

- [ ] Every `REPLACE_ME_` placeholder in `values/` and `manifests/` is
      replaced (search the tree with
      `grep -RIn 'REPLACE_ME_' values manifests | sort`).
- [ ] Grafana admin password is created as a Secret out-of-band (sealed
      secret, External Secrets Operator, or `kubectl create secret`
      from a one-shot terminal — never in a values file).
- [ ] Loki GCS bucket exists, has lifecycle rules matching the 15d
      retention policy, and uniform bucket-level access denies public read.
- [ ] Tempo GCS bucket exists with matching lifecycle (7–15d) and same
      access controls.
- [ ] GCS access uses GKE Workload Identity: each component's KSA
      (`netra-loki`, `netra-tempo`) is bound to a GSA with
      `roles/storage.objectAdmin` on its bucket. No static keys, no
      credential Secret mounted.
- [ ] Dedicated observability node pool exists, labelled
      `workload=observability`, tainted
      `workload=observability:NoSchedule`.
- [ ] `REPLACE_ME_SSD_STORAGECLASS` is set to a real, SSD-backed
      `StorageClass` for the cluster.
- [ ] Prometheus `external_labels` are set per environment
      (`environment: dev|stage|prod`, `cluster: <name>`). One Helm
      release per environment cluster, same chart, different external
      labels.

## After install

- [ ] `scripts/verify.sh` returns 0.
- [ ] `scripts/validate.sh` returns 0 in CI.
- [ ] Grafana datasources `Prometheus`, `Loki`, `Tempo`, `Alertmanager`
      all show green health.
- [ ] All 10 dashboards are visible under `Netra / Platform`,
      `Netra / Services`, `Netra / OPA`, `Netra / RUM`.
- [ ] Every PrometheusRule shows `health: ok` in
      `https://<grafana>/alerting/list` filtered by `netra` label.
- [ ] No alert is firing on the Netra stack itself.
- [ ] At least one blackbox probe target per env returns
      `probe_success == 1`.

## Security posture

- [ ] No public ingress for Grafana, Prometheus, Loki, Tempo, or
      Alertmanager. Access is via cluster-internal Service + port-forward,
      a private LB with mTLS, or an authenticated ingress (e.g.
      OAuth2 Proxy).
- [ ] Alertmanager receiver tokens (PagerDuty, Slack, Opsgenie, SMTP)
      are mounted from a Secret, **not** committed to this repo. The
      Alertmanager `route` block in
      `values/kube-prometheus-stack/values.yaml` ships with `null`
      receivers; flip them on as receivers are wired.
- [ ] Network policies restrict the `observability` namespace ingress
      to: kube-system, prometheus operator endpoints, and the app
      namespaces that need to push OTLP.
- [ ] No `request_id`, `trace_id`, `span_id`, `user_id`, `email`,
      `session_id`, or `tenant_id` is being used as a Loki label.
      Cross-check with `logcli labels` after first 24h of ingest.

## Health expectations

- [ ] Prometheus PVC usage < 50% after first 24h.
- [ ] Loki ingest 5xx rate is zero outside of brief restart windows.
- [ ] Tempo block_retention matches policy (7d, or 15d if changed).
- [ ] Alloy DaemonSet is running on every node in the cluster, including
      app pools.

## During the Datadog overlap window

- [ ] Datadog still installed, still collecting, still paging.
- [ ] No on-call route is moved off Datadog until the relevant service
      has dashboards + alerts + runbooks + at least one validated
      incident on Netra. See `datadog-migration.md`.

## Out of scope (do not silently add)

- Thanos / Mimir / Cortex
- OpenSearch / Elasticsearch / Logstash
- Pyroscope, Backstage, OpenCost, Trivy, Falco
- Any data warehouse or long-term analytics archival
- A Netra CLI

Any of these become real proposals through a follow-up RFC, not a quiet
commit to this repo.
