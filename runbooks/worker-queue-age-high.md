# WorkerQueueAgeHigh / WorkerThroughputDrop

Alerts: `WorkerQueueAgeHigh`, `WorkerThroughputDrop`
Severity: `warning`
Owner: backend

## What it means

The oldest pending job in a worker queue has been waiting more than 5
minutes (`WorkerQueueAgeHigh`), or worker throughput has fallen below 50%
of the trailing-hour average for 15 minutes (`WorkerThroughputDrop`).

## Where to look

- Grafana: `Netra / Services / Python Workers` — `Throughput by queue`,
  `Oldest queued job age`.
- Logs:
  ```
  {service_name="$service", environment="$environment"} |~ "queue|backoff|locked"
  ```

## Immediate actions

1. Check live worker count and HPA state:
   ```sh
   kubectl get hpa -n <ns> | grep worker
   ```
2. Check broker/queue health (Redis/SQS/Kafka — whichever the service uses).
3. Look for stuck "in-flight" jobs holding a lock.

## Mitigation

- Scale workers manually if HPA is too slow.
- Requeue / cancel stuck jobs after confirming they are safe to retry.
- If a downstream dependency (DB / external API) is slow, see if it is
  the actual root cause.

## Escalation

Page the backend on-call if the queue age keeps climbing after scaling
workers, or if the backlog threatens an SLO (e.g. ingestion freshness).
