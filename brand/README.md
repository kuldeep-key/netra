# Netra brand assets · Identity v2

Vector logos and icons for Netra. Full guidelines: [Netra Identity v2 — Design System & Brand Guidelines](https://claude.ai/public/artifacts/d5235d04-d586-4b07-bd7a-5d2707a61883).

## Mark

The symbol is a bold **N** with a **Signal Blue** live node (`#0057FF`) at the top-right of the stroke — the focal point for health and attention.

## Files

| File | Use |
| --- | --- |
| [`netra-logo-horizontal.svg`](netra-logo-horizontal.svg) / [`.png`](netra-logo-horizontal.png) | README, docs — **use PNG in Markdown** (GitHub blocks SVG in README) |
| [`netra-logo-horizontal-dark.svg`](netra-logo-horizontal-dark.svg) / [`.png`](netra-logo-horizontal-dark.png) | Dark backgrounds (GitHub dark mode, Grafana login) |
| [`netra-logo-stacked.svg`](netra-logo-stacked.svg) / [`.png`](netra-logo-stacked.png) | Centered layouts, profile-style headers |
| [`netra-logo-stacked-dark.svg`](netra-logo-stacked-dark.svg) / [`.png`](netra-logo-stacked-dark.png) | Stacked on dark backgrounds |
| [`netra-symbol.svg`](netra-symbol.svg) / [`.png`](netra-symbol.png) | Symbol only — light background |
| [`netra-symbol-white.svg`](netra-symbol-white.svg) / [`.png`](netra-symbol-white.png) | Symbol only — dark background |
| [`netra-wordmark.svg`](netra-wordmark.svg) | Wordmark only — light background (vector; prefer PNG in Markdown) |
| [`netra-wordmark-white.svg`](netra-wordmark-white.svg) | Wordmark only — dark background |
| [`netra-icon.svg`](netra-icon.svg) / [`.png`](netra-icon.png) | App icon — squircle on Signal Ink |
| [`netra-icon-circle.svg`](netra-icon-circle.svg) | App icon — circle on Signal Ink |
| [`favicon.svg`](favicon.svg) / [`.png`](favicon.png) | Browser tab / small UI chrome |
| [`social-preview.png`](social-preview.png) | GitHub social preview (1280×640) |

## Color tokens

| Token | Hex | Use |
| --- | --- | --- |
| Signal Blue | `#0057FF` | Live node · links · brand accent |
| Signal Ink | `#0B0D12` | Dark backgrounds · icon fills |
| Signal Paper | `#F7F8FC` | Light surfaces |
| Signal Green | `#2DBA4E` | Healthy · reconciled |
| Signal Amber | `#F5A623` | Attention · warning |
| Signal Critical | `#D94040` | Critical · page sparingly |
| Signal Mono | `#111111` | Symbol and wordmark on light backgrounds |

## Clear space

Keep at least **0.5× symbol height** of padding around the mark. Do not recolor the live node except for monochrome print (`Signal Mono`).

## In this repo

- **README** — horizontal logo PNG with `prefers-color-scheme` swap (SVG is for vector/Grafana only)
- **Grafana** — `install.sh` mounts `netra-symbol-white.svg` as the login icon via `netra-grafana-branding` ConfigMap
- **GitHub social card** — set repository social preview to `brand/social-preview.png` (Settings → General → Social preview)

## Voice

Direct, engineering-first, ownership over gloss. Tagline: **Observability you own.**
