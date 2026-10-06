# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0


FROM docker.io/library/python:3.14.7-alpine3.23@sha256:218761489de417a6eb0808e264cbdd7043ec6659fe5a61898815e9848536541d AS build-venv

RUN apk update && \
    apk add gcc g++ linux-headers

COPY ./src/recommendation/requirements.txt requirements.txt

RUN python -m venv venv && \
    venv/bin/pip install --no-cache-dir --require-hashes -r requirements.txt

RUN venv/bin/opentelemetry-bootstrap -a install

FROM docker.io/library/python:3.14.7-alpine3.23@sha256:218761489de417a6eb0808e264cbdd7043ec6659fe5a61898815e9848536541d

COPY --from=build-venv /venv/ /venv/

WORKDIR /app

COPY ./src/recommendation/demo_pb2_grpc.py demo_pb2_grpc.py
COPY ./src/recommendation/demo_pb2.py demo_pb2.py
COPY ./src/recommendation/logger.py logger.py
COPY ./src/recommendation/metrics.py metrics.py
COPY ./src/recommendation/recommendation_server.py recommendation_server.py

EXPOSE ${RECOMMENDATION_PORT}
ENTRYPOINT [ "/venv/bin/opentelemetry-instrument", "/venv/bin/python", "recommendation_server.py" ]
