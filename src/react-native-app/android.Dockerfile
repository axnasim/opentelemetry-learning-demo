# syntax=docker/dockerfile:1

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# https://github.com/react-native-community/docker-android
# Pick a tag whose Android build tools match what Expo's version catalog
# generates in android/build.gradle so the container doesn't re-download them.
FROM reactnativecommunity/react-native-android:v21.1@sha256:d4b8ea0773d62096261cf0ed356004fe2c8292f5e5cdb260d11da953c8c84374 AS builder

WORKDIR /reactnativesrc/
COPY . .

RUN npm ci
# Regenerate the android/ project from app.json using Expo's continuous native
# generation. `--no-install` skips a redundant install since dependencies are already present.
RUN npx expo prebuild --platform android --no-install
WORKDIR android/
RUN chmod +x gradlew
RUN ./gradlew assembleRelease

FROM scratch
COPY --from=builder /reactnativesrc/android/app/build/outputs/apk/release/app-release.apk /reactnativeapp.apk
ENTRYPOINT ["/reactnativeapp.apk"]
