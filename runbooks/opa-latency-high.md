# OpaDecisionLatencyHigh

Alert: `OpaDecisionLatencyHigh`
Severity: `warning`
Owner: platform

## What it means

OPA p95 decision latency on `v1/data*` handlers has been above 50ms for
10 minutes. Slow OPA decisions cascade into Python API latency for any
endpoint that calls OPA on the request path.

## Where to look

- Grafana: `Netra / OPA` — `Decision latency percentiles`.
- Logs:
  ```
  {service_name="opa", environment="$environment"}
  ```
- Tempo: `service.name="opa"` traces.

## Immediate actions

1. Identify the slow query handler from the p95 panel breakdown.
2. Check bundle size and recent bundle reloads:
   ```sh
   kubectl exec -n <ns> deploy/opa -- /opa eval --metrics 'data.policy.allow == true'
   ```
3. Inspect OPA CPU/memory — is it throttled?

## Mitigation

- Increase OPA replica count / CPU.
- Roll back the most recent bundle if it ships a new policy that uses
  expensive iterations.
- Add partial evaluation / caching for hot queries.

## Escalation

Page the platform on-call if p95 stays above 100ms for 15 minutes or if
Python API latency starts climbing in lockstep.
