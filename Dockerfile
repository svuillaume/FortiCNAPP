# Stage 1 — build a custom Caddy binary that includes the DuckDNS DNS provider
# (needed for the Let's Encrypt DNS-01 challenge)
FROM caddy:builder AS builder
RUN xcaddy build --with github.com/caddy-dns/duckdns

# Stage 2 — minimal runtime image
FROM caddy:latest

LABEL org.opencontainers.image.title="GenAISec — Fortinet"
LABEL org.opencontainers.image.description="Fortinet GenAI Security Insights — HTTPS via Let's Encrypt + DuckDNS DNS-01"

# Drop in the custom Caddy binary that knows about DuckDNS
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Site configuration
COPY Caddyfile /etc/caddy/Caddyfile

# Static content (served from /srv inside the container)
COPY docs/ /srv/

# 80  — HTTP (Caddy auto-redirects to HTTPS)
# 443 — HTTPS
# 2019 — Caddy admin API (health checks, config reload)
EXPOSE 80 443 2019

# Caddy admin API is always plain HTTP on port 2019 — safe for internal health checks
HEALTHCHECK --interval=60s --timeout=10s --retries=3 --start-period=30s \
  CMD wget -q --spider http://localhost:2019/config/ || exit 1
