# NodeNotReady

Alert: `NodeNotReady`
Severity: `critical`
Owner: platform

## What it means

A Kubernetes node has reported `Ready=false` (or stopped reporting) for at
least 5 minutes. Pods on the node are no longer accepting new traffic and
the scheduler will start evicting workloads.

## Where to look

- Grafana: `Netra / Platform / Kubernetes` — filter by `cluster`, `node`.
- Logs: `{cluster="$cluster", namespace="kube-system"} |= "kubelet"` in Loki.
- `kubectl describe node <node>` for the `Conditions` block.

## Immediate actions

1. Identify the node:
   ```sh
   kubectl get nodes -o wide | grep -v ' Ready '
   ```
2. Check the condition reason:
   ```sh
   kubectl describe node <node> | sed -n '/Conditions:/,/^[A-Z]/p'
   ```
3. Common causes and first responses:
   - **Kubelet down** — SSH to node, `systemctl status kubelet`, restart.
   - **Network partition** — check VPC / security group / route table.
   - **Disk full** — see `node-disk-pressure.md`.
   - **Node lost / replaced by autoscaler** — drain gracefully if possible
     and let the autoscaler replace it.

## Mitigation

- If the node holds observability workloads, cordon and drain it so they
  reschedule on another `workload=observability` node:
  ```sh
  kubectl cordon <node>
  kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
  ```

## Escalation

If more than one node in the same pool is `NotReady`, page the platform
on-call lead. This usually indicates infra-level damage (control plane,
network, cloud provider).
