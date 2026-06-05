# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A containerised static blog delivering Fortinet GenAI Security content. It deploys to two targets simultaneously:
- **GitHub Pages** — push to `main`, site deploys automatically at `https://svuillaume.github.io/genAISeC/`
- **Self-hosted Docker** — Caddy serves HTTPS via ZeroSSL DNS-01 challenge over DuckDNS

All content is in `docs/` — there is no build step, no bundler, no framework.

## Development commands

**Local dev (instant, no Docker needed):**
```bash
docker run --rm -p 8080:80 \
  -v $(pwd)/docs:/usr/share/nginx/html/genAISeC:ro \
  nginx:alpine
# → http://localhost:8080/genAISeC/
```

**Production HTTPS (needs `.env` filled in):**
```bash
cp .env.example .env   # fill DOMAIN, LE_EMAIL, DUCKDNS_TOKEN, AUTH_USER, AUTH_PASS
docker compose up -d
docker compose logs -f  # watch cert issuance on first start
docker compose ps       # confirm healthy
```

**After changing content:**
```bash
docker compose build && docker compose up -d
```

**Generate bcrypt hash for AUTH_PASS:**
```bash
docker run --rm caddy:latest caddy hash-password --plaintext 'yourpassword'
```

## Architecture

```
Browser → Caddy (:443)
            ├─ / → 301 /genAISeC/
            ├─ /genAISeC/* → file_server from /srv  (= docs/ in image)
            └─ /health → 200
```

The Dockerfile does a two-stage build: `caddy:builder` compiles a custom Caddy binary with the `caddy-dns/duckdns` plugin (`xcaddy build`), then copies it into `caddy:latest`. The DuckDNS plugin is what allows the DNS-01 TLS challenge to work without port 80.

`nginx.conf` is kept for reference but is **not used** — the active server is Caddy.

`caddy_data` Docker volume holds the TLS cert — **never delete it** (ZeroSSL/Let's Encrypt rate-limits duplicate cert requests to 5/week per domain).

## Content and design system

All HTML pages share one embedded `<style>` block (no external stylesheet). When updating styles, edit them in every affected page — they are not linked from a shared file.

**CSS component classes to know:**
- `.wf-wrap / .wf-track / .wf-step` — five-layer workflow grid at top of `blog.html`
- `.fnet-diagram / .fnet-card / .fnet-cols` — Fortinet coverage architecture diagrams
- `.csp-badge.aws/.azure/.gcp/.sent` — cloud provider inline badges
- `.fortiguard-callout` — dark navy intelligence callout block
- `.png-gallery / .png-card` — architecture screenshot gallery
- `.callout / .risk-card` — general callout boxes

**Glossary popups** — each page's `<script>` block scans `document.body` for known terms (defined in the `TERMS` array), wraps them in `<span class="gl-term">`, and shows a `#gl-popup` tooltip on hover/tap. Adding a term: append `{ t: "Term", def: "...", level: 1–5 }` to the `TERMS` array and add `#gl-popup` CSS if the page is missing it.

**Search & filter (index page)** — client-side only. Each `.card` element has `data-tags="..."` and `data-search="..."` attributes. The JS in `index.html` filters on keyup and tag-click. Tags must match exactly what is listed in the filter bar pills.

## Adding a new post

1. Copy `docs/blog-nvidia.html` as starting template — it has the correct `<nav class="topnav">`, breadcrumb, `.meta`, hero structure, and glossary JS.
2. Add a card to `docs/index.html`: set `data-tags`, `data-search`, `.card-date`, and card body pill badges.
3. Update the hero `<a class="btn">` in `index.html` to point to the new post.
4. Commit and push — GitHub Pages deploys automatically; run `docker compose build && up -d` for self-hosted.

## Environment variables

All consumed by `Caddyfile` via `{env.VAR}` syntax:

| Variable | Used in | Notes |
|---|---|---|
| `DOMAIN` | Caddyfile site block | e.g. `samvblogs.duckdns.org` |
| `LE_EMAIL` | Caddyfile `email` directive | ZeroSSL contact |
| `DUCKDNS_TOKEN` | Caddyfile `dns duckdns` | DNS-01 challenge credential |
| `AUTH_USER` | Caddyfile `basicauth` | Plain username |
| `AUTH_PASS` | Caddyfile `basicauth` | **Must be bcrypt hash** (see generate command above) |
| `AUTH_SECRET` | Reserved | Future HMAC session middleware |
| `TLS_CERT` / `TLS_KEY` | Optional | Pre-existing cert paths — not yet wired into Caddyfile |
