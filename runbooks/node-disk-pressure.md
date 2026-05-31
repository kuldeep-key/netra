# NodeDiskPressure

Alert: `NodeDiskPressure`
Severity: `warning`
Owner: platform

## What it means

The kubelet on a node has reported `DiskPressure=true` for at least 5
minutes. New pods will not schedule and existing pods may be evicted.

## Where to look

- Grafana: `Netra / Platform / Kubernetes` — `Node memory/disk` panels.
- `kubectl describe node <node>` for the `Allocated resources` block.

## Immediate actions

1. Find the noisy disks:
   ```sh
   kubectl describe node <node> | grep -E 'ephemeral-storage|disk'
   ```
2. SSH or `kubectl debug node/<node>` and check:
   ```sh
   df -h
   du -h /var/lib/docker /var/lib/containerd 2>/dev/null | sort -h | tail
   ```
3. Identify the culprit pod:
   ```sh
   kubectl get pods -A -o wide --field-selector spec.nodeName=<node>
   ```
   Look for high log volume or local ephemeral storage usage.

## Mitigation

- Clean up dangling images (`crictl rmi --prune`) if container runtime is
  full.
- Cordon the node and let the autoscaler replace it.
- If a single pod's logs are blowing up disk, check Alloy/Loki ingestion
  — see `loki-ingestion-errors.md`.

## Escalation

If multiple nodes hit DiskPressure within a 30-minute window, treat as a
capacity/log-storm incident and page the platform on-call lead.
