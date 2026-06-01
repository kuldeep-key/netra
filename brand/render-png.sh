#!/usr/bin/env bash
# Regenerate brand/*.png from brand/*.svg (requires: npx, @resvg/resvg-js-cli).
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

render() { npx --yes @resvg/resvg-js-cli --fit-width "$1" "$2" "${2%.svg}.png"; }

render 560 netra-logo-horizontal.svg
render 560 netra-logo-horizontal-dark.svg
render 240 netra-logo-stacked.svg
render 240 netra-logo-stacked-dark.svg
render 96  netra-symbol.svg
render 96  netra-symbol-white.svg
render 512 netra-icon.svg
render 64  favicon.svg
render 1280 social-preview.svg

echo "brand PNGs rendered."
