# Datadog migration

## Rule one: Datadog stays

This task installs Netra in parallel with Datadog. **Do not remove,
disable, or downgrade Datadog as part of standing up Netra.** Datadog is
ground truth during validation and incident response. Netra has to earn
the trust before anything depends on it.

## Sequence

1. **Install Netra** (this task). Empty, validate against placeholders,
   confirm health from `Netra / Platform / *` dashboards.
2. **Wire app metrics in parallel.** Apps already send to Datadog; add
   Prometheus client / OTel exporters that *also* push to Netra. Datadog
   remains the on-call signal during this window.
3. **Run for one full release cycle** with both Datadog and Netra live.
   Compare:
   - p50/p95/p99 of the same Python API endpoint between the two.
   - Error rates on the same service.
   - On-call alerts: are Datadog + Netra firing the same incidents at
     roughly the same time? Document discrepancies.
4. **Service-by-service cutover.** When a service shows green on Netra
   for a release cycle, swap its on-call routes from Datadog to
   Alertmanager. Keep the Datadog agent installed for one extra cycle as
   a safety net.
5. **Datadog teardown** happens in a separate task, after every service
   has migrated and we have observed at least one incident handled
   end-to-end on Netra alone.

## What "validation" means before cutover

For a given service:

- Required metrics are present in Prometheus (`up`, request rate, error
  rate, latency percentiles, queue age for workers).
- Alerts are wired to a real receiver (PagerDuty/Slack via a secret-managed
  Alertmanager config — **not** committed to this repo).
- A dashboard exists under `Netra / Services / <service>`.
- A runbook exists under `runbooks/`.
- At least one synthetic blackbox probe target exists for the
  customer-facing path.

## What does NOT change in this task

- App code stays untouched.
- Datadog agent DaemonSets / sidecars stay running.
- Datadog dashboards, monitors, and SLOs stay live.
- No on-call routes move to Alertmanager yet.

## What can change immediately

- Platform-level dashboards (Kubernetes, Loki/Tempo/Prometheus/Alloy
  health, blackbox) are safe to look at from Netra today.
- Internal users can start exploring Netra dashboards via port-forward.
