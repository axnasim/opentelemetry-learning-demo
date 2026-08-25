# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0


FROM docker.io/library/python:3.14.6-slim-bookworm@sha256:a70519002c49552ea0a853de47599cf40479b001bd7a624f1112eaf44dcaccc7 AS base

FROM base AS builder
RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends g++ \
    && rm -rf /var/lib/apt/lists/*

COPY ./src/load-generator/requirements.txt .
RUN pip install --prefix="/reqs" --require-hashes -r requirements.txt

FROM base
WORKDIR /usr/src/app/
COPY --from=builder /reqs /usr/local
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
RUN playwright install --with-deps chromium
COPY ./src/load-generator/locustfile.py .
COPY ./src/load-generator/people.json .
ENTRYPOINT ["locust", "--skip-log-setup"]
