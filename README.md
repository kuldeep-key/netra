<div align="center">

# Netra · नेत्र

### Observability you own.

**Vision for your infrastructure — clarity across Kubernetes chaos.**

[![Open Source](https://img.shields.io/badge/Open%20Source-OSS-0057FF?style=flat-square&labelColor=0B0D12)](https://github.com/kuldeep-key/netra)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-GKE%20%7C%20any%20serious%20K8s-F7F8FC?style=flat-square&labelColor=0B0D12&color=0057FF)](docs/production-checklist.md)
[![Signals](https://img.shields.io/badge/Signals-Metrics%20%7C%20Logs%20%7C%20Traces-2DBA4E?style=flat-square&labelColor=0B0D12)](docs/architecture.md)
[![GitOps](https://img.shields.io/badge/Dashboards%20%26%20Alerts-Git--owned-F7F8FC?style=flat-square&labelColor=0B0D12&color=0057FF)](docs/dashboards-alerts-in-git.md)

</div>

---

Netra is the **open-source observability boilerplate** for Kubernetes teams who want to **own the stack** — not rent it, not rebuild it from scratch every quarter.

Netra ships metrics, logs, traces, optional browser RUM, dashboards, alerts, and on-call runbooks — **pinned, versioned in Git**, and reproducible. **One Grafana workspace** per estate: a central hub can watch many Kubernetes clusters; a single cluster runs the full stack locally. App environments are **labels** on workloads.

Apps adopt a [published contract](docs/app-integration.md). This repo stays generic. Your services show up when they label their pods correctly. That's the multiplier.

---

## Trace · Node · Ownership

Netra's identity is built on three ideas — and they're how the platform works:

| | Idea | In the product |
| --- | --- | --- |
| **Trace** | One unbroken path through the stack | OTLP and Alloy carry signals end-to-end — prompts, spans, logs, metrics on the same line |
| **Node** | A focal point that tells you if things are alive | The live node on the mark maps to health: green when reconciled, amber when attention needed, red when paging |
| **Ownership** | Your cluster, your buckets, your Git | No surveillance gloss, no vendor lock-in — fork-friendly YAML, your GCS, your on-call |

---

## The fork in the road

Most teams eventually choose between three bad options:

- **Keep renting** observability — fast to start, expensive at scale, hard to exit
- **Build from charts** — powerful, but weeks of glue and dashboards someone edited at 2am
- **Do nothing** — until the outage where nobody can answer *which environment* or *which service* broke

Netra is the third path: an **opinionated, extensible boilerplate** with the glue, conventions, and GitOps discipline already wired. Platform work should **multiply** product teams, not block them.

---

## Who Netra is for

| You are… | Netra helps you… |
| --- | --- |
| **Platform / DevOps** on GKE or serious K8s | Install a coherent stack with one script — not a spreadsheet of chart versions |
| **Startup with GCP credits** | Run real metrics/logs/traces without a five-figure SaaS line item |
| **Team validating self-hosted obs** | Run **alongside** your vendor, prove parity, cut over on your timeline ([migration guide](docs/datadog-migration.md)) |
| **OSS contributor** | Extend a boilerplate built for **more tools, not more forks** ([roadmap](#roadmap--extension-model)) |

Want turn-key SaaS with zero cluster ops? Netra isn't that — and we won't pretend otherwise. Want **control, composability, and a repo you can fork without shame**, you're in the right place.

---

## What ships on day one

| Signal | Stack | What Netra adds |
| --- | --- | --- |
| **Metrics** | Prometheus, Alertmanager, kube-state-metrics | Git-owned rules, ServiceMonitor conventions, platform + service dashboards |
| **Logs** | Loki → GCS | Alloy DaemonSet, cardinality guardrails, structured pipeline |
| **Traces** | Tempo → GCS | OTel Collector as blessed ingest; direct Tempo blocked by policy |
| **Synthetic** | blackbox_exporter | Stack health probes + pattern for per-app external checks |
| **RUM** | Grafana Faro via Alloy | Optional browser SDK; CORS hooks ready to configure |
| **Operations** | Markdown runbooks | Every critical alert links to a playbook |

**GitOps by default:** 10+ dashboards, PrometheusRules, datasource ConfigMaps, network policies for ingest. UI edits are drafts until exported and committed — [dashboards-alerts-in-git.md](docs/dashboards-alerts-in-git.md).

**Env-neutral:** Netra has no dev/stage/prod of its own — applications carry `environment: dev | stage | prod` on pods and spans. Dashboards filter on environment; multi-cluster deployments also filter on `cluster`.

**Deployment topologies:**

| Topology | Where the stack runs | How apps connect |
| --- | --- | --- |
| **Single-cluster** | Full stack on one Kubernetes cluster | Local scrape, Alloy, and OTLP ([`install.sh`](scripts/install.sh)) |
| **Multi-cluster hub** | Full stack on one central cluster; agents on each app cluster | Agents forward telemetry to the hub; Grafana filters on `cluster` × `environment` ([`NETRA_*` hooks](scripts/install.sh)) |

Single-cluster:

```
┌─────────────────────────────────────────┐
│  Netra — full stack on this cluster     │
│  namespace: observability               │
└─────────────────────────────────────────┘
                    ▲
        ┌───────────┼───────────┐
   my-api (dev)  my-api (stage)  my-api (prod)
   same ServiceMonitor · same dashboards · different series
```

Multi-cluster hub:

```
  app-cluster-dev ──agents──┐
  app-cluster-stg ──agents──┼──►  Netra central (one Grafana)
  app-cluster-prod ─agents──┘     cluster × environment
```

Architecture: [docs/architecture.md](docs/architecture.md)

---

## Architecture

```
  YOUR APPS (any namespace)              NETRA (observability namespace)
  ─────────────────────────              ─────────────────────────────────

  stdout ─────────────────────────────►  Alloy ──► Loki ──► GCS
  /metrics ────────────────────────────►  Prometheus ──► Grafana OSS
  OTLP traces ─────────────────────────►  OTel Collector ──► Tempo ──► GCS
  Faro RUM (optional) ─────────────────►  Alloy ──► Loki / Tempo

  blackbox probes ◄── stack health + your app URLs (optional)
  Alertmanager ◄── PrometheusRules (Git-owned)
```

---

## Get started

### 1. Clone and install

**Prerequisites:** Kubernetes (GKE recommended for GCS + Workload Identity), `kubectl`, `helm`, `jq`, `envsubst`, and a dedicated observability node pool:

| Setting | Value |
| --- | --- |
| Machine type | **`e2-standard-2`** (2 vCPU, 8 GiB) — default; **`e2-standard-4`** if cardinality is high |
| Label | `workload=observability` |
| Taint | `workload=observability:NoSchedule` |

Complete [production-checklist.md](docs/production-checklist.md) before install: GCS buckets, Workload Identity on Loki/Tempo, node pool ready. `install.sh` preflights both (`SKIP_GCS_PREFLIGHT=1` for non-GCS smoke tests only).

```sh
git clone https://github.com/kuldeep-key/netra.git
cd netra
# optional: NETRA_CLUSTER=my-gke-cluster ./scripts/install.sh
./scripts/install.sh
```

**Pinned charts (May 2026):** kube-prometheus-stack **86.1.0** · Loki **17.1.5** · Tempo **2.2.0** · Alloy **1.8.2** · OTel Collector **0.158.0** · blackbox_exporter **11.9.1**

`install.sh` is idempotent — safe to re-run.

### 2. Verify

```sh
./scripts/verify.sh           # in-cluster sanity check
./scripts/verify.sh --deep      # + Prometheus targets + memory budget
./scripts/validate.sh           # local lint — no cluster needed
```

### 3. Open Grafana

```sh
./scripts/port-forward.sh grafana
# → http://localhost:3000

kubectl get secret -n observability netra-grafana-admin \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

Browse **Netra / Platform** for stack health, then [connect your first service](#connect-your-first-service).

**Tear down:** `./scripts/uninstall.sh` (PVCs and GCS buckets preserved by default)

**Production:** [production-checklist.md](docs/production-checklist.md)

**Multi-cluster hub:** configure via `NETRA_*` extension hooks in [`scripts/install.sh`](scripts/install.sh). Private overlays are maintained outside this public repo.

---

## Connect your first service

Netra contains **zero application code**. Your service repo wires instrumentation; Netra collects. Full spec: [app-integration.md](docs/app-integration.md)

1. **Metrics** — Prometheus on Service port `http-metrics`
2. **Labels** — on pods: `environment`, `team`, `app.kubernetes.io/name`
3. **Scrape class** — on Service metadata: `app.kubernetes.io/component: api` (or `worker`)
4. **Traces** — OTLP to `netra-otel-collector.observability.svc.cluster.local:4317`
5. **Logs** — JSON to stdout; Alloy handles the rest

```yaml
# Deployment pod template
labels:
  app.kubernetes.io/name: payments-api
  app.kubernetes.io/component: payments-api
  team: payments
  environment: prod

# Service metadata (ServiceMonitor discovery)
labels:
  app.kubernetes.io/component: api
```

Three Deployments with `environment: dev`, `stage`, `prod` — same name, different labels — all appear in **Netra / Services / Python API** without a PR to this repo.

**Synthetic checks:** add a Probe in [blackbox-probes.yaml](manifests/prometheus/servicemonitors/blackbox-probes.yaml) with `layer: app` and `environment: dev|stage|prod`.

---

## Configuration

| Setting | Location | Default |
| --- | --- | --- |
| Cluster identity | `values/cluster.yaml` or `NETRA_CLUSTER` | `netra` |
| PVC storage class | kps, loki, tempo values | `standard` |
| Log / trace buckets | loki/tempo values | `netra-loki-data`, `netra-tempo-data` |
| GKE Workload Identity | loki/tempo `serviceAccount.annotations` | unset — add your GSA |
| Grafana admin | auto-created by install | Secret `netra-grafana-admin` |
| RUM CORS | `values/alloy/values.yaml` | `http://localhost:3000` |

| Signal | Retention | Backend |
| --- | --- | --- |
| Metrics | 15 days | Prometheus PVC |
| Logs | 15 days | Loki → GCS |
| Traces | 7 days (configurable to 15) | Tempo → GCS |
| Dashboards, alerts, runbooks | indefinite | Git |

---

## Roadmap & extension model

Netra is a **boilerplate, not a cage**. New tools land through **RFC + focused PR** — not drive-by commits ([production-checklist.md](docs/production-checklist.md)).

**Core bundle (today):** Grafana OSS · Prometheus · Alertmanager · Loki · Alloy · Tempo · OpenTelemetry Collector · blackbox_exporter · Git-owned dashboards, alerts, runbooks

**Integration layers (roadmap):**

| Layer | Examples | Value |
| --- | --- | --- |
| Long-term metrics | Thanos, Mimir | Beyond 15d without SaaS |
| Profiling | Pyroscope, Parca | Continuous profiling ↔ traces |
| Security signals | Falco, Trivy | Runtime risk alongside app metrics |
| Cost visibility | OpenCost patterns | Platform cost transparency |
| Chaos & reliability | Litmus, probe extensions | Game days in the same alert loop |

Extension points: `values/` per component, namespace manifests, sidecar-loaded dashboards — boring on purpose so new tools feel native.

---

## Repository layout

```
netra/
├── values/           Helm values — one directory per component
├── manifests/        Namespace, network policies, ServiceMonitors, PrometheusRules
├── dashboards/       Grafana JSON — sidecar ConfigMaps
├── runbooks/         On-call playbooks linked from alerts
├── scripts/          install · uninstall · verify · validate · port-forward
└── docs/             Architecture, integration contract, checklists, migration
```

---

## Documentation

| Document | When to read |
| --- | --- |
| [architecture.md](docs/architecture.md) | Pipelines, scheduling, storage, multi-env model |
| [app-integration.md](docs/app-integration.md) | Wiring a new service |
| [production-checklist.md](docs/production-checklist.md) | Beyond a dev cluster |
| [dashboards-alerts-in-git.md](docs/dashboards-alerts-in-git.md) | GitOps workflow for Grafana |
| [datadog-migration.md](docs/datadog-migration.md) | Validating against an existing vendor |

---

## Principles

- **One observability workspace per estate** — single Grafana for all environments; multi-cluster deployments use a central hub with agents on app clusters
- **Environments are labels** — `dev`, `stage`, and `prod` live on app workloads
- **Cluster is a label in hub mode** — app-cluster agents stamp `cluster` so Grafana can slice across Kubernetes clusters
- **Apps own instrumentation; Netra owns the plane** — services conform to [app-integration.md](docs/app-integration.md); this repo stays generic
- **Git is source of truth** for dashboards, alerts, and datasources
- **No secrets in Git** — credentials live in Secrets, Workload Identity, or your secret manager
- **Cluster-internal by default** — Grafana, Prometheus, Loki, and Tempo stay off the public internet unless you expose them with auth
- **Low-cardinality Loki labels** — high-cardinality IDs belong in log bodies
- **Durable object storage in production** — GCS for logs and traces; node disks for cache

---

## Brand · Identity v2

For logos, color tokens, and usage: [Netra Identity v2 — Design System & Brand Guidelines](https://claude.ai/public/artifacts/d5235d04-d586-4b07-bd7a-5d2707a61883)

| Token | Hex | Use |
| --- | --- | --- |
| Signal Blue | `#0057FF` | Brand default · live node · links |
| Signal Ink | `#0B0D12` | Dark backgrounds |
| Signal Paper | `#F7F8FC` | Light surfaces |
| Signal Green | `#2DBA4E` | Healthy · reconciled |
| Signal Amber | `#F5A623` | Attention · warning |
| Signal Critical | `#D94040` | Critical · page sparingly |
| Signal Mono | `#111111` | Monochrome · print |

**Voice:** direct, engineering-first, ownership over gloss. Say what Netra is and isn't.

---

## Status

Netra is a **scaffold you can run today**, not a hosted product with a SLA. You own buckets, node pools, alert receivers, and on-call routing.

Before production: [production-checklist.md](docs/production-checklist.md). Before app adoption: [app-integration.md](docs/app-integration.md).

We're building in the open because observability infrastructure belongs in the commons — composable, forkable, extensible.

<div align="center">

**See your whole cluster. Know which environment broke. Own the stack.**

Star the repo · open an issue · send a PR

</div>
