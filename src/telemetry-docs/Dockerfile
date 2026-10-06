# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Two-stage build: Generate service-centric Markdown with Weaver, then serve with mkdocs

# -----------------------------------------------------------------------------
# Stage 1: Registry Processing
# Uses Weaver to transform raw OTel YAML schemas into Markdown documentation
# and a dynamically generated mkdocs.yml configuration.
# -----------------------------------------------------------------------------
FROM docker.io/otel/weaver:v0.26.1@sha256:9094862c0ab261bdbcb079bb981f9a573b3659b130a6d2ab8616eca6ba37aaec AS registry-builder

# Switch to root temporarily to configure workspace permissions
USER root

WORKDIR /workspace

# Create the target directory AND make sure the home cache directory belongs to weaver
RUN mkdir -p /workspace/docs /home/weaver/.weaver && \
    chown -R 10001:10001 /workspace /workspace/docs /home/weaver

# Switch back to the safe non-root weaver user
USER 10001

# FORCE Weaver to look into our writeable workspace for its cache files
ENV XDG_CACHE_HOME=/workspace/.cache
ENV HOME=/workspace

# Copy the telemetry schema
COPY telemetry-schema /workspace/telemetry-schema

# Copy the Weaver templates
COPY src/telemetry-docs/templates /workspace/templates

# Generate service-centric pages and mkdocs.yml using Weaver
RUN /weaver/weaver registry generate \
    --registry=/workspace/telemetry-schema \
    --templates=/workspace/templates \
    markdown \
    /workspace/docs

# Generate packaged resolved schema
RUN /weaver/weaver registry package \
    --registry=/workspace/telemetry-schema \
    --resolved-schema-uri=https://opentelemetry.io/schemas/1.40.0 \
    --output=/workspace/docs/schema \
    --v2

# -----------------------------------------------------------------------------
# Stage 2: Documentation Generation
# Uses MkDocs (Python) to convert Markdown artifacts into a static HTML site.
# -----------------------------------------------------------------------------
FROM docker.io/library/python:3.14-slim-bookworm@sha256:c8137f4c460908c8763f281c8f22c431eb5c538514ba9553fc3a89c06b7cfb88 AS site-builder

WORKDIR /app

COPY src/telemetry-docs/requirements.txt /app/requirements.txt

# Use a stable Python environment for MkDocs generation
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

COPY src/telemetry-docs/mkdocs.yml /app/mkdocs-base.yml
# Copy the Markdown files AND the generated mkdocs.yml from Stage 1
COPY --from=registry-builder /workspace/docs /app/docs

RUN mv /app/docs/mkdocs.yml /app/mkdocs.yml && \
    mkdocs build --clean

# -----------------------------------------------------------------------------
# Stage 3: Production
# Minimal Nginx server to host the static assets.
# -----------------------------------------------------------------------------
FROM docker.io/nginxinc/nginx-unprivileged:1.31.2-alpine3.23-otel@sha256:1490cbf02ddba36ae75ef947b570166c805a178898ebfbc3bb889e7580820052

USER 101

COPY --from=site-builder /app/site /static
COPY src/telemetry-docs/nginx.conf.template /nginx.conf.template

EXPOSE ${TELEMETRY_DOCS_PORT}

STOPSIGNAL SIGQUIT

# Start nginx
CMD ["/bin/sh" , "-c" , "envsubst '$OTEL_COLLECTOR_HOST $OTEL_COLLECTOR_PORT_GRPC $OTEL_SERVICE_NAME $TELEMETRY_DOCS_PORT' < /nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]
