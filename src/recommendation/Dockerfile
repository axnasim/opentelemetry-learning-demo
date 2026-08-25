# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0


FROM docker.io/library/python:3.14.6-alpine3.23@sha256:02da11a8d221ca167aa07de20b3cd7104c1f01227f4b02b1fa13cf6517280a81 AS build-venv

RUN apk update && \
    apk add gcc g++ linux-headers

COPY ./src/recommendation/requirements.txt requirements.txt

RUN python -m venv venv && \
    venv/bin/pip install --no-cache-dir --require-hashes -r requirements.txt

RUN venv/bin/opentelemetry-bootstrap -a install

FROM docker.io/library/python:3.14.6-alpine3.23@sha256:02da11a8d221ca167aa07de20b3cd7104c1f01227f4b02b1fa13cf6517280a81

COPY --from=build-venv /venv/ /venv/

WORKDIR /app

COPY ./src/recommendation/demo_pb2_grpc.py demo_pb2_grpc.py
COPY ./src/recommendation/demo_pb2.py demo_pb2.py
COPY ./src/recommendation/logger.py logger.py
COPY ./src/recommendation/metrics.py metrics.py
COPY ./src/recommendation/recommendation_server.py recommendation_server.py

EXPOSE ${RECOMMENDATION_PORT}
ENTRYPOINT [ "/venv/bin/opentelemetry-instrument", "/venv/bin/python", "recommendation_server.py" ]
