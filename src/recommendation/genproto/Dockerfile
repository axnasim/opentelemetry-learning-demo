# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/library/python:3.14.8-slim-bookworm@sha256:c8137f4c460908c8763f281c8f22c431eb5c538514ba9553fc3a89c06b7cfb88

WORKDIR /build

COPY ./src/recommendation/genproto/requirements.txt requirements.txt

RUN python -m pip install --no-cache-dir --require-hashes -r requirements.txt
