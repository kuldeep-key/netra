# WorkerFailureRateHigh / WorkerRetrySpike

Alerts: `WorkerFailureRateHigh`, `WorkerRetrySpike`
Severity: `critical` / `warning`
Owner: backend

## What it means

More than 5% of jobs have failed in the last 15 minutes
(`WorkerFailureRateHigh`), or retry rate exceeds 1/s for 10 minutes
(`WorkerRetrySpike`).

## Where to look

- Grafana: `Netra / Services / Python Workers` — `Jobs by status`,
  `Retries/s`.
- Loki:
  ```
  {service_name="$service", environment="$environment", level="error"}
    |~ "failed|exception|traceback"
  ```
- Tempo: look at failing job spans by `worker.job.name`.

## Immediate actions

1. Group failures by job type / handler:
   - Grafana panel `Jobs by status` with `job_name` breakdown if exported.
2. Read the most recent error stacktrace from logs.
3. Check downstream dependency status (DB, external APIs, S3).

## Mitigation

- Pause the offending job type if the platform supports it.
- Roll back the most recent worker deploy if the timing matches.
- Move bad messages to a dead-letter queue.

## Escalation

Page the backend on-call if failure rate stays above 10% for 10 minutes
or any job type produces a sustained > 50% failure rate.
