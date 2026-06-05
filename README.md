# Fortinet · GenAI Security Insights

A containerised static blog delivering Fortinet GenAI Security posts and PreSales reference content — self-hosted on Docker with automatic HTTPS, and mirrored on GitHub Pages.

**Self-hosted:** https://samvblogs.duckdns.org/  
**GitHub Pages:** https://svuillaume.github.io/FortiCNAPP/

---

## Content

| Page | File | Description |
|---|---|---|
| Home | `docs/index.html` | Card listing with live search and tag filtering |
| Walk the GenAISec Talk | `docs/blog.html` | Five-layer GenAI attack surface — CVEs, Fortinet coverage, vendor landscape (May 21, 2026) |
| Autonomous Patching | `docs/ai-security-hook-blog.html` | FortiCNAPP Code Security plugin analysis — pre-commit vs post-task modes (Jun 4, 2026) |
| FortiAIGate × NVIDIA | `docs/blog-nvidia.html` | Press-release PreSales breakdown (May 22, 2026) |
| Reference Guide | `docs/reference.html` | FortiAI pillar framework, FortiAIGate deep-dive, FortiOS 8.0, MCP visibility, field talking points |

All pages share an embedded design system: Fortinet red (`#EE3124`) / dark navy (`#1a1a2e`) palette, interactive glossary popups, and a responsive layout down to 375 px.

---

## Running Locally

**Instant dev server (no Docker build needed):**
```bash
docker run --rm -p 8080:80 \
  -v $(pwd)/docs:/usr/share/nginx/html:ro \
  nginx:alpine
# → http://localhost:8080/
```

---

## Production HTTPS Setup

The image uses **[Caddy](https://caddyserver.com/)** with the [caddy-dns/duckdns](https://github.com/caddy-dns/duckdns) module compiled in. Caddy obtains and renews TLS certificates automatically via the **ZeroSSL DNS-01 challenge** — no certbot, no cron job, no port 80 required.

### Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose ≥ 24 | Docker Desktop or Docker Engine |
| DuckDNS domain → your server IP | Set at [duckdns.org](https://www.duckdns.org) |
| Ports 80 and 443 open | Caddy handles HTTP → HTTPS redirect on :80 |
| DuckDNS token | Found on your DuckDNS account page |

### 1 — Configure environment

```bash
cp .env.example .env
# Fill in DOMAIN, LE_EMAIL, DUCKDNS_TOKEN
```

`.env` is git-ignored and never committed.

### 2 — Build and start

```bash
docker compose up -d
docker compose logs -f   # watch ZeroSSL cert issuance on first start
```

On first start Caddy will:
1. Register a ZeroSSL account for your email
2. Call the DuckDNS API to set the `_acme-challenge` TXT record
3. ZeroSSL validates and issues a 90-day cert
4. Caddy serves HTTPS and auto-renews before expiry — no intervention needed

### 3 — Verify

```bash
docker compose ps                        # confirm healthy
curl -I https://samvblogs.duckdns.org/   # expect HTTP 200
```

### Updating content

```bash
docker compose down
docker compose build
docker compose up -d
```

> **Never delete the `caddy_data` volume** — it holds the TLS certificate. ZeroSSL rate-limits duplicate cert requests to 5 per week per domain.

---

## Architecture

```
Browser
  │
  ├─ HTTP :80  ──► Caddy ──► 301 → HTTPS
  │
  └─ HTTPS :443 ─► Caddy
                     │  TLS: ZeroSSL via DNS-01 (DuckDNS)
                     │  Auto-renewed — no manual steps
                     │
                     ├─ GET /              → /srv/index.html
                     ├─ GET /*.html        → /srv/*.html
                     ├─ GET /genAISeC*     → 301 /   (legacy)
                     ├─ GET /FortiCNAPP*   → 301 /   (legacy)
                     └─ GET /health        → 200 OK

Docker volumes
  caddy_data   — TLS certificates (persist across restarts)
  caddy_config — Caddy internal config cache
```

---

## Adding a New Blog Post

1. Copy `docs/blog-nvidia.html` as a template — it has the correct nav, breadcrumb, meta, and glossary JS
2. Add a card to `docs/index.html`:
   - `data-tags="..."` — space-separated tags from the filter bar
   - `data-search="..."` — keywords for the search index
   - `.card-tags` pill badges and `.card-date` inside `.card-body`
3. Update the hero `<a class="btn">` in `index.html` to point to the new post
4. `git add . && git commit && git push` — GitHub Pages deploys automatically; run `docker compose build && docker compose up -d` for the self-hosted version

---

## Environment Variables

| Variable | Required | Notes |
|---|---|---|
| `DOMAIN` | Yes | Your DuckDNS FQDN, e.g. `samvblogs.duckdns.org` |
| `LE_EMAIL` | Yes | ZeroSSL/ACME contact email |
| `DUCKDNS_TOKEN` | Yes | From your DuckDNS account page |
| `TLS_CERT` / `TLS_KEY` | No | Path to pre-existing cert — not yet wired into Caddyfile |

---

## Security Headers

| Header | Value |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `SAMEORIGIN` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Server` | *(removed)* |

---

## License

&copy; 2026 Fortinet, Inc. All rights reserved.  
Content is proprietary to Fortinet and intended for internal PreSales use. See the disclaimer on each page for full terms.
