# PythonApiHighP95Latency

Alert: `PythonApiHighP95Latency`
Severity: `warning`
Owner: backend

## What it means

p95 request latency for a Python API service has been above 1s for 10
minutes.

## Where to look

- Grafana: `Netra / Services / Python API` — `Latency percentiles` panel.
- Tempo: search slow traces by `service.name="$service"` and sort by
  duration.
- Loki: look for upstream timeout strings:
  ```
  {service_name="$service", environment="$environment"} |~ "timeout|slow|deadlock"
  ```

## Immediate actions

1. Identify the slow endpoint: drill down by `path` / `route` in the
   latency panel.
2. Check downstream health (DB CPU, replica lag, cache hit rate).
3. Inspect a slow trace in Tempo — what span dominates?

## Mitigation

- Add an HPA bump or temporary replica increase.
- Disable the offending feature flag.
- If the slow endpoint is a query, kill long-running queries or shed load
  via rate limiting.

## Escalation

Page the backend on-call if p95 stays > 2s for 15 minutes or starts
contributing to 5xx (see `python-api-high-5xx.md`).
