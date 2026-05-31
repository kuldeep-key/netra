#!/usr/bin/env bash
# Netra observability install.
#
# Idempotent. Reapply at any time.
# Requirements: kubectl, helm, jq.
#
# Usage:
#   ./scripts/install.sh
#
# Pinned to current stable chart releases (2026-05-31):
#   kube-prometheus-stack 86.1.0 | loki 17.1.5 | alloy 1.8.2 | tempo 2.2.0
#   opentelemetry-collector 0.158.0 | prometheus-blackbox-exporter 11.9.1
#
# Loki + Tempo charts: grafana-community (grafana/helm-charts is GEL-only after Mar 2026).

set -euo pipefail

NS=observability
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VALUES_DIR="$REPO_ROOT/values"
MANIFESTS_DIR="$REPO_ROOT/manifests"
DASHBOARDS_DIR="$REPO_ROOT/dashboards"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required tool: $1" >&2
    exit 1
  }
}

require kubectl
require helm
require jq

# -------------------------------------------------------------------------
# 1. Helm repos
# -------------------------------------------------------------------------
say "Adding Helm repos"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add grafana              https://grafana.github.io/helm-charts             >/dev/null
helm repo add grafana-community    https://grafana-community.github.io/helm-charts   >/dev/null
helm repo add open-telemetry       https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null
helm repo update >/dev/null

# -------------------------------------------------------------------------
# 2. Namespace + base manifests
# -------------------------------------------------------------------------
say "Applying namespace"
kubectl apply -f "$MANIFESTS_DIR/namespace.yaml"
kubectl apply -f "$MANIFESTS_DIR/node-scheduling.yaml"

# -------------------------------------------------------------------------
# 3. Helm releases
# -------------------------------------------------------------------------
say "Installing kube-prometheus-stack (netra-kps)"
helm upgrade --install netra-kps prometheus-community/kube-prometheus-stack \
  --namespace "$NS" \
  --version 86.1.0 \
  --values "$VALUES_DIR/kube-prometheus-stack/values.yaml" \
  --wait

say "Installing Loki (netra-loki)"
helm upgrade --install netra-loki grafana-community/loki \
  --namespace "$NS" \
  --version 17.1.5 \
  --values "$VALUES_DIR/loki/values.yaml" \
  --wait

say "Installing Alloy (netra-alloy)"
helm upgrade --install netra-alloy grafana/alloy \
  --namespace "$NS" \
  --version 1.8.2 \
  --values "$VALUES_DIR/alloy/values.yaml" \
  --wait

say "Installing Tempo (netra-tempo)"
helm upgrade --install netra-tempo grafana-community/tempo \
  --namespace "$NS" \
  --version 2.2.0 \
  --values "$VALUES_DIR/tempo/values.yaml" \
  --wait

say "Installing OpenTelemetry Collector (netra-otel-collector)"
helm upgrade --install netra-otel-collector open-telemetry/opentelemetry-collector \
  --namespace "$NS" \
  --version 0.158.0 \
  --values "$VALUES_DIR/otel-collector/values.yaml" \
  --wait

say "Installing blackbox_exporter (netra-blackbox)"
helm upgrade --install netra-blackbox prometheus-community/prometheus-blackbox-exporter \
  --namespace "$NS" \
  --version 11.9.1 \
  --values "$VALUES_DIR/blackbox-exporter/values.yaml" \
  --wait

# -------------------------------------------------------------------------
# 4. Manifests: datasources, ServiceMonitors, PrometheusRules, probes
# -------------------------------------------------------------------------
say "Applying datasources ConfigMap"
kubectl apply -f "$MANIFESTS_DIR/grafana/datasources-configmap.yaml"

say "Applying ServiceMonitors and blackbox Probes"
kubectl apply -f "$MANIFESTS_DIR/prometheus/servicemonitors/"

say "Applying PrometheusRules"
kubectl apply -f "$MANIFESTS_DIR/prometheus/prometheusrules/"

say "Applying blackbox probe catalog (informational)"
kubectl apply -f "$MANIFESTS_DIR/blackbox/probes-configmap.yaml"

# -------------------------------------------------------------------------
# 5. Dashboards -> ConfigMaps (grafana_dashboard=1)
# -------------------------------------------------------------------------
say "Packaging dashboards/*.json into ConfigMaps"
shopt -s nullglob
for f in "$DASHBOARDS_DIR"/*.json; do
  base="$(basename "$f" .json)"
  cm_name="netra-dashboard-$base"

  jq empty "$f"

  folder="$(jq -r '.title // ""' "$f" | awk -F' / ' '{print $1" / "$2}')"

  kubectl create configmap "$cm_name" \
    --namespace "$NS" \
    --from-file="$base.json=$f" \
    --dry-run=client -o yaml | \
    kubectl label --local -f - \
      grafana_dashboard=1 \
      app.kubernetes.io/part-of=netra \
      --dry-run=client -o yaml | \
    kubectl annotate --local -f - \
      grafana_folder="$folder" \
      --dry-run=client -o yaml | \
    kubectl apply -f -
done
shopt -u nullglob

say "Done. Run scripts/verify.sh to check cluster state."
