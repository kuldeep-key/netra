# Netra architecture

Netra is one shared observability stack that watches every environment
(dev, stage, prod) through labels, namespaces, and dashboard variables.

## Signals at a glance

```
+----------------+        +-------+        +-------+        +---------+
|  pods (any ns) | stdout |       |        |       |        |         |
| dev/stage/prod | -----> | Alloy | -----> | Loki  | -----> |         |
+----------------+        |  ds   |        |  GCS  |        |         |
                          +-------+        +-------+        |         |
                                                            |         |
+----------------+        +-----------------------+         |         |
|   pods + nodes |        | Prometheus (kps)      |         |         |
| /metrics + ksm | -----> | scrape across all ns  | ------> |         |
+----------------+        | + Alertmanager        |         | Grafana |
                          +-----------------------+         |   OSS   |
                                  |                         |         |
                                  v                         |         |
                          +-----------------------+         |         |
                          |   PrometheusRules     |         |         |
                          +-----------------------+         |         |
                                                            |         |
+----------------+        +-------+        +-------+        |         |
|  app services  | OTLP   | OTel  |        | Tempo |        |         |
|                | -----> | Coll. | -----> |  GCS  | -----> |         |
+----------------+        +-------+        +-------+        |         |
                              ^                             |         |
                              |                             |         |
+----------------+            |                             |         |
| Next.js Faro   |   HTTPS    |   logs   +-------+          |         |
| SDK (optional) | -----> Alloy ------> Loki     |          |         |
+----------------+         (Faro recv)  +-------+           |         |
                              |                             |         |
                              +---- traces -----------------+         |
                                                            +---------+
```

## Per-signal pipelines

- **Logs:** pod stdout → Alloy DaemonSet → Loki (single-binary) → GCS
  object storage → Grafana (Loki datasource).
- **Metrics:** kubelet/cAdvisor + kube-state-metrics + node-exporter +
  ServiceMonitors → Prometheus (kube-prometheus-stack) → Grafana
  (Prometheus datasource). Alertmanager fires PrometheusRule alerts.
- **Traces:** apps → OpenTelemetry Collector → Tempo → GCS → Grafana
  (Tempo datasource).
- **RUM:** Next.js Faro SDK (optional) → Alloy Faro receiver → Loki for
  events, Tempo for traces → Grafana.

## Cross-environment tracking

One stack covers all envs. Every signal carries:

- `environment` (dev | stage | prod)
- `cluster`
- `namespace`
- `service` / `service_name`
- `pod`
- `team`

Prometheus injects `cluster` and `environment` as `external_labels` so
every metric and every alert is environment-stamped automatically. Alloy
copies `environment` and `cluster` onto every log stream. The OTel
Collector upserts `deployment.environment` and `cluster` resource
attributes on every span.

Dashboards expose `environment` (and `service` where applicable) as
template variables so one dashboard answers the same question for any
env.

## Node isolation, not HA

Observability workloads run on a dedicated `workload=observability` node
pool. Components scheduled there:

- Grafana, Prometheus, Alertmanager, Prometheus Operator,
  kube-state-metrics
- Loki, Tempo, OpenTelemetry Collector
- blackbox_exporter

Alloy and node-exporter run on every node (DaemonSet with
`tolerations: Exists`) so they can collect from app pools.

**Isolation, not HA.** A dedicated observability node protects app pools
from observability load and vice-versa, but a single-node setup is still
a single point of failure for Netra itself. True HA requires:

- 3+ observability nodes spread across AZs
- replicated/stateless Loki/Tempo deployment modes (read/write/backend
  split) — out of scope for this scaffold
- Prometheus Operator HA (replicas: 2 with shard-aware Alertmanager
  clustering)

We will not pretend HA exists until we make those changes.

## Storage

- **Prometheus:** SSD PVC, 15d retention.
- **Loki:** GCS object storage, 15d retention. Local PVC is WAL/cache only.
  GCS auth via GKE Workload Identity (no static keys).
- **Tempo:** GCS object storage, 7d retention (configurable up to 15d via
  `tempo.retention`). Local PVC is WAL only. GCS auth via GKE Workload
  Identity.
- **Grafana:** small PVC for plugins and session data; dashboards and
  datasources are reloaded from ConfigMaps every restart.
- **Dashboards / alerts / datasources / runbooks:** Git is the source of
  truth, forever.
