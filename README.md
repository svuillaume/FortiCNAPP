# Fortinet · GenAI Security Insights

A containerised static web app delivering Fortinet GenAI Security blog posts and PreSales reference content — published on GitHub Pages and self-hostable anywhere Docker runs.

**Live site:** https://svuillaume.github.io/FortiCNAPP/  
**Self-hosted (HTTPS):** https://mydevsecops.duckdns.org/FortiCNAPP/

---

## Content

| Page | Path | Description |
|---|---|---|
| Home / Index | `docs/index.html` | Card listing with live search and tag filtering |
| NVIDIA Blog Post | `docs/blog-nvidia.html` | FortiAIGate × NVIDIA press-release PreSales breakdown (May 22, 2026) |
| GenAISec Blog Post | `docs/blog.html` | Five-layer GenAI attack surface breakdown with CVEs and Fortinet coverage (May 21, 2026) |
| Reference Guide | `docs/reference.html` | FortiAI pillar framework, FortiAIGate deep-dive, FortiOS 8.0, MCP visibility, and field talking points |

All pages share a common design system:
- Fortinet red (`#EE3124`) and dark navy (`#1a1a2e`) brand palette
- Official Fortinet logomark from [icons.fortinet.com](https://icons.fortinet.com)
- Interactive glossary popups — hover or tap any underlined term for a plain-language definition
- Responsive layout down to 375 px

---

## Features

### Search & Tag Filtering (index page)
The home page includes a client-side search bar and tag filter pills. No server required — all filtering runs in the browser.

**Available tags:** `FortiAIGate` · `NVIDIA` · `CNAPP` · `GenAI Threats` · `Field Guide` · `Press Release`

Type any keyword (product name, technology, CVE, author term) and the cards filter instantly. Tag and text filters combine — active tag narrows the set, search narrows further within it.

### Glossary Popups
Every page scans its body text for known terms and wraps them with a dotted red underline. Hover or click to see a Quick Definition card with a plain-language explanation and (for core security concepts) a five-rung complexity ladder.

---

## Running Locally

### Option A — GitHub Pages (no Docker needed)
The `docs/` folder is the GitHub Pages source. Push to `main` and the site deploys automatically.

### Option B — Docker (HTTP, dev mode)
```bash
docker compose up
```
Opens at **http://localhost:8080/FortiCNAPP/**

The `docs/` folder is volume-mounted so edits appear without rebuilding the image.

> **Note:** The current `docker-compose.yml` is configured for the HTTPS production setup (see below). For a plain HTTP dev server, run nginx directly:
> ```bash
> docker run --rm -p 8080:80 \
>   -v $(pwd)/docs:/usr/share/nginx/html/FortiCNAPP:ro \
>   nginx:alpine
> ```

### Option C — Docker HTTPS (production, Let's Encrypt)
See the full setup below.

---

## HTTPS Container Setup

The production image uses **[Caddy](https://caddyserver.com/)** with the [caddy-dns/duckdns](https://github.com/caddy-dns/duckdns) module baked in. Caddy handles TLS cert issuance and renewal automatically via the **Let's Encrypt DNS-01 challenge** — no certbot sidecar, no cron job, no manual renewal.

### Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose | Docker Desktop or Docker Engine ≥ 24 |
| Domain pointing to your server | `mydevsecops.duckdns.org` → your public IP (set in [duckdns.org](https://www.duckdns.org)) |
| Ports 80 and 443 open | Required for Caddy to serve HTTP→HTTPS redirect and HTTPS |
| DuckDNS token | Found on your DuckDNS account page after login |

### 1 — Configure your token

```bash
cp .env.example .env
# Open .env and replace the placeholder with your real DuckDNS token
```

`.env` is git-ignored and never committed.

### 2 — Build and start

```bash
docker compose up -d
```

On first start Caddy will:
1. Call the DuckDNS API to set an `_acme-challenge` TXT record on your domain
2. Let's Encrypt validates the TXT record and issues a 90-day cert
3. Caddy begins serving HTTPS and automatically redirects HTTP → HTTPS
4. Cert is renewed automatically before expiry — no intervention needed

The site is live at **https://mydevsecops.duckdns.org/FortiCNAPP/**

### 3 — Verify

```bash
docker compose ps          # confirm container is healthy
docker compose logs -f     # watch Caddy output including cert issuance
curl -I https://mydevsecops.duckdns.org/FortiCNAPP/
```

### Stopping and updating

```bash
docker compose down        # stop (certs are safe in the caddy_data volume)
docker compose build       # rebuild after content changes
docker compose up -d       # restart
```

> **Important:** Never delete the `caddy_data` Docker volume. It holds the Let's Encrypt certificate. Losing it and requesting a new cert too often triggers Let's Encrypt [rate limits](https://letsencrypt.org/docs/rate-limits/) (5 duplicate certs per week per domain).

---

## Project Structure

```
FortiCNAPP/
├── docs/                        # Web content (GitHub Pages source)
│   ├── index.html               # Home page — search, tag filtering, card listing
│   ├── blog-nvidia.html         # Blog: FortiAIGate × NVIDIA breakdown
│   ├── blog.html                # Blog: Five-layer GenAI attack surface
│   └── reference.html           # PreSales reference & positioning guide
│
├── Dockerfile                   # Multi-stage: xcaddy builds DuckDNS module → runtime image
├── Caddyfile                    # Caddy config: HTTPS, DNS-01, routing, security headers
├── docker-compose.yml           # Production compose: ports 80/443, caddy_data volume
├── nginx.conf                   # Legacy nginx config (kept for reference, superseded by Caddy)
├── .env.example                 # Token template — copy to .env before running
├── .gitignore                   # Excludes .env, .DS_Store, editor dirs
└── .dockerignore                # Excludes .git, markdown, secrets from image build
```

---

## Architecture

```
Browser
  │
  ├─ HTTP :80  ──► Caddy ──► 301 → HTTPS
  │
  └─ HTTPS :443 ─► Caddy
                     │  TLS cert: Let's Encrypt (DNS-01 via DuckDNS API)
                     │  Auto-renewed before expiry
                     │
                     ├─ GET /                  → 301 /FortiCNAPP/
                     ├─ GET /FortiCNAPP/         → /srv/index.html
                     ├─ GET /FortiCNAPP/*.html   → /srv/*.html
                     └─ GET /health            → 200 OK  (health probe)

Docker volumes
  caddy_data   — TLS certificates (persist across restarts)
  caddy_config — Caddy internal config cache
```

---

## Adding a New Blog Post

1. Create `docs/your-post.html` — copy `blog-nvidia.html` as a template
2. Add a card to `docs/index.html`:
   - Set `data-tags="..."` (space-separated, from the tag list above)
   - Set `data-search="..."` (keywords for the search index)
   - Add `.card-tags` pill badges inside `.card-body`
   - Set `class="card-date"` with the publish date
3. Update the hero `<a class="btn">` link in `index.html` to point to the new post
4. Commit and push — GitHub Pages deploys automatically; rebuild the Docker image for the self-hosted version

---

## Security Headers (enforced by Caddy)

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
