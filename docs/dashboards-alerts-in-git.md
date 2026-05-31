# Dashboards and alerts in Git

Netra treats Git as the source of truth for everything observable:

| Asset       | Location                                              | Format             |
| ----------- | ----------------------------------------------------- | ------------------ |
| Dashboards  | `dashboards/`                                         | Grafana JSON       |
| Alerts      | `manifests/prometheus/prometheusrules/`               | `PrometheusRule`   |
| Datasources | `manifests/grafana/datasources-configmap.yaml`        | Grafana ConfigMap  |
| Runbooks    | `runbooks/`                                           | Markdown           |
| Probes      | `manifests/prometheus/servicemonitors/blackbox-*.yaml`| `Probe` CRDs       |

## Why

- One source of truth survives Grafana / Prometheus reinstalls.
- Code review on dashboards and alerts catches bad PromQL before it
  pages on-call.
- Every change is traceable to a commit and a reviewer.
- New environments come up with the same dashboards on day one.

## How it loads

- The Grafana sidecar (enabled in
  `values/kube-prometheus-stack/values.yaml`) watches all namespaces for
  ConfigMaps with `grafana_dashboard=1` or `grafana_datasource=1` labels.
- `scripts/install.sh` packages each `dashboards/*.json` into a
  ConfigMap named `netra-dashboard-<name>` with the
  `grafana_dashboard=1` label and a `grafana_folder` annotation derived
  from the dashboard title (`Netra / Platform / ...` etc).
- PrometheusRules and ServiceMonitors are picked up by the Prometheus
  Operator across all namespaces (selectors are nil in the chart
  values).

## Dashboard folders

Dashboard JSON titles use a `Netra / <folder> / <name>` pattern so the
sidecar files them into Grafana folders:

- `Netra / Platform` — infrastructure dashboards (Kubernetes,
  Prometheus / Loki / Tempo / Alloy / blackbox health).
- `Netra / Services` — service dashboards (Python API, Python workers).
- `Netra / OPA` — OPA decision and bundle dashboards.
- `Netra / RUM` — Next.js Faro RUM dashboards.
- `Netra / Alerts` — alert overview dashboards (add later if needed).

## Making changes

1. Edit the JSON / YAML in this repo.
2. Open a PR. `scripts/validate.sh` runs in CI without a cluster.
3. After merge, `scripts/install.sh` reapplies on the next deploy.

## Manual Grafana UI edits

UI edits are **temporary**. The sidecar will not overwrite them while
the pod is alive, but any restart, replacement, or `helm upgrade` will
restore the Git version.

When a UI edit is worth keeping:

1. Export the dashboard JSON from Grafana
   (`Share > Export > Save to file`, set "Export for sharing externally"
   off so UIDs and datasource UIDs are preserved).
2. Commit it over the existing `dashboards/<name>.json`.
3. Open a PR. The reviewer checks for regressions in template variables
   (`environment` etc.) and that no datasource UID has been silently
   replaced.

Anything not exported and committed is treated as lost on the next
rollout.
