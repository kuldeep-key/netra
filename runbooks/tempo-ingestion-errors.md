# TempoIngestionErrors

Alert: `TempoIngestionErrors`
Severity: `critical`
Owner: platform

## What it means

Tempo's ingest path is returning 5xx errors for 10+ minutes. Traces from
the OpenTelemetry Collector and the Faro receiver are not landing in
object storage. Live trace search is still possible from the in-memory
ingester for a short window.

## Where to look

- Grafana: `Netra / Platform / Tempo health` — `Tempo request rate by
  route/status`.
- Tempo pod logs:
  ```sh
  kubectl logs -n observability statefulset/netra-tempo -c tempo --tail=200
  ```
- OpenTelemetry Collector logs (it is the upstream):
  ```sh
  kubectl logs -n observability deploy/netra-otel-collector --tail=200
  ```

## Immediate actions

1. Confirm the GCS backend is reachable from the Tempo pod and Workload
   Identity is bound (see `loki-ingestion-errors.md` for the recipe).
2. Check Tempo ingester memory and disk WAL:
   ```sh
   kubectl describe pod -n observability -l app.kubernetes.io/name=tempo
   ```
3. Look for compactor errors in the logs — these can backpressure ingest.

## Mitigation

- Roll Tempo if it looks stuck:
  ```sh
  kubectl rollout restart -n observability statefulset/netra-tempo
  ```
- If the OTel Collector is the bottleneck, scale `replicaCount` in
  `values/otel-collector/values.yaml` and reapply.
- If the cause is GCS (Workload Identity binding broken, bucket IAM
  changed), fix the underlying KSA→GSA binding / bucket IAM.

## Escalation

Page the platform on-call. Tracing is observability-only — no customer
impact from Tempo being down, but trace data lost during the outage is
gone for good.
