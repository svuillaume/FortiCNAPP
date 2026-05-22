FROM nginx:alpine

LABEL org.opencontainers.image.title="GenAISec — Fortinet"
LABEL org.opencontainers.image.description="Fortinet GenAI Security Insights: blog posts and PreSales reference"

# Drop the default vhost config
RUN rm /etc/nginx/conf.d/default.conf

# Custom nginx config (serves at /genAISeC/ to match GitHub Pages path)
COPY nginx.conf /etc/nginx/conf.d/genaisec.conf

# Static content
COPY docs/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost/health || exit 1
