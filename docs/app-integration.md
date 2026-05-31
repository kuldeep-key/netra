# Application integration contract

Netra is a **plug-and-play** observability platform. It publishes the
stable contract below; any service in any repository adopts it to get
logs, metrics, traces, and RUM **without changing anything in this repo**.

Netra deliberately knows nothing about specific applications. This is the
separation of concerns that keeps it reusable:

- **Netra owns** the platform: collectors, Prometheus/Grafana/Alertmanager,
  Loki, Tempo, Alloy, the scrape conventions, and the generic platform
  dashboards/alerts.
- **Each service owns** its own instrumentation, its app-specific
  dashboards/alerts, and conforming to the contract here.

If a future repo wants observability, it implements this contract — Netra
is not edited to "know about" it.

## Metrics (Prometheus)

Expose `/metrics` on a Service port named **`http-metrics`**.

### Labels — Service metadata vs pod labels

ServiceMonitors match **Service metadata**, not pod labels. Prometheus relabeling
copies **pod** labels into metric series (`service`, `team`, `environment`) and
copies **Service metadata** into `scrape_class`:

| Label | Where it lives | Purpose |
|-------|----------------|---------|
| `app.kubernetes.io/component: api \| worker` | **Service metadata** | Selects `netra-python-api` or `netra-python-worker` ServiceMonitor; copied to `scrape_class` on scraped series |
| `app.kubernetes.io/name: <service>` | **Pod** labels | Becomes the Prometheus `service` label |
| `team`, `environment` | **Pod** labels | Relabeled onto every scraped series |
| `app.kubernetes.io/component: <routing-id>` | **Pod** labels (optional) | Immutable deployment identity (e.g. `decision-engine`, `mcp-gateway`); **not** used for scrape selection |

When a workload's routing component differs from its scrape class (common for
sidecar-style services), set `component: api` on the **Service** metadata only
and keep the pod/Deployment selector on the routing value.

Example Service metadata for an HTTP API scrape target:

```
app.kubernetes.io/component:  api          # scrape class → scrape_class="api"
team:                         <team>
environment:                  dev | stage | prod
```

Example pod labels (become `service`, `team`, `environment` on series):

```
app.kubernetes.io/name:      <service>
app.kubernetes.io/component:  <routing-id>   # may differ from scrape class
team:                         <team>
environment:                  dev | stage | prod
```

- ServiceMonitors are namespace-agnostic (`namespaceSelector: any`), so a
  conforming workload in **any** namespace is scraped automatically.
- Platform alerts and dashboards filter on `scrape_class="api"` or
  `scrape_class="worker"`, not on pod routing labels.
- **OPA**: expose a Service labelled `app.kubernetes.io/name: opa` with an
  `http-metrics` port (the `netra-opa` ServiceMonitor matches it).
- Need a component beyond `api`/`worker`? Add a generic ServiceMonitor here
  keyed on a convention — never one named after a single app.

## Traces (OpenTelemetry)

Send OTLP to the in-cluster collector:

```
netra-otel-collector.observability.svc.cluster.local:4317   # gRPC
netra-otel-collector.observability.svc.cluster.local:4318   # HTTP
```

The collector upserts `deployment.environment` and `cluster` resource
attributes on every span, so services need not set them.

## Logs (Alloy → Loki)

- Write structured logs to **stdout**. Alloy's per-node DaemonSet collects
  them automatically; no sidecar, no Promtail.
- **Low-cardinality labels only**: `environment`, `namespace`,
  `service_name`, `pod`, `container`, `level`, `cluster`, `team`. Keep
  `request_id` / `trace_id` / `span_id` / `user_id` / `tenant_id` in the
  log body or structured metadata — **never** as Loki labels.
- Emit `trace_id` / `span_id` in logs to light up Loki↔Tempo correlation.

## RUM (browser, optional)

Point a Grafana Faro Web SDK at the Alloy Faro receiver ingress:

```
https://REPLACE_ME_FARO_INGRESS_HOST/collect
```

## Alerting expectations

The bundled platform PrometheusRules assume conventional metric families.
A service either emits these names, or ships its own PrometheusRule with
its own repo/overlay — it does not edit Netra's rules.

| Domain | Expected series |
|--------|-----------------|
| HTTP API | `http_requests_total`, `http_request_duration_seconds_bucket` |
| Workers | `worker_jobs_total`, `worker_jobs_retried_total`, `worker_jobs_processed_total`, `worker_queue_oldest_job_age_seconds` |
| OPA | `opa_decisions_total`, `opa_bundle_*`, `http_request_duration_seconds` |

## Out of scope for this repo

- Application instrumentation code.
- App-specific dashboards/alerts beyond the generic platform set.

Adopting the contract is the only integration step. Netra stays reusable
because consumers conform to it — the dependency points at Netra, never the
other way around.
