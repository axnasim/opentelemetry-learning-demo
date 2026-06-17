# OpenTelemetry Demo — Codebase Reference

A complete map of every folder and file in this repository and what each one does.

---

## Top-Level Layout

```
opentelemetry-demo/
├── .github/               # GitHub automation (CI, issue templates, ownership)
├── internal/              # Developer tooling (not compiled into any service)
├── pb/                    # Protobuf schema — the contract between all services
├── src/                   # All service source code
├── telemetry-schema/      # Formal schema for every custom OTel attribute and metric
├── test/                  # Integration and telemetry pipeline tests
└── [root files]           # Config, compose files, Makefile, linting
```

---

## `.github/`

GitHub-specific automation. Not part of the running application.

### `.github/workflows/`

| Workflow | Trigger | What it does |
|---|---|---|
| `checks.yml` | PR | Runs linting: misspell, markdownlint, yamllint, license headers, link checker |
| `build-images.yml` | Push to main / release | Builds and pushes all Docker images to `ghcr.io/open-telemetry/demo` |
| `component-build-images.yml` | PR touching a service | Builds only the affected service image |
| `run-integration-tests.yml` | PR / push | Starts the full stack and runs trace-based tests (Tracetest) |
| `run-telemetry-tests.yml` | PR / push | Starts the full stack and verifies telemetry flows to Jaeger/Prometheus/OpenSearch |
| `nightly-release.yml` | Nightly cron | Builds and tags a nightly image |
| `release.yml` | Tag push | Cuts an official versioned release |
| `codeql-analysis.yml` | PR / push | GitHub CodeQL security scanning |
| `ossf-scorecard.yml` | Weekly | OpenSSF Scorecard supply chain security score |
| `fossa.yml` | PR / push | License compliance scanning |
| `dependabot-auto-update-protobuf-diff.yml` | Dependabot PR | Auto-regenerates proto stubs when a gRPC dependency bumps |
| `react-native-build.yml` | PR touching mobile app | Builds the React Native Android app |
| `gradle-wrapper-validation.yml` | PR | Validates Gradle wrapper checksums (security) |
| `assign-reviewers.yml` | PR opened | Auto-assigns reviewers from `component_owners.yml` |
| `label-pr.yml` | PR opened | Auto-labels PR by which component files changed |
| `stale.yml` | Cron | Marks and closes stale issues/PRs |
| `zizmor.yml` | PR / push | Audits GitHub Actions workflows for security issues |

### Other `.github/` files

| File | Purpose |
|---|---|
| `CODEOWNERS` | Maps file paths to GitHub users who must approve PRs touching them |
| `component_owners.yml` | Per-service owner list used by the reviewer assignment workflow |
| `dependabot.yml` | Configures Dependabot to auto-open PRs for dependency updates per ecosystem |
| `PULL_REQUEST_TEMPLATE.md` | Pre-fills PR description with a checklist contributors must follow |
| `ISSUE_TEMPLATE/bug_report.md` | Bug report form |
| `ISSUE_TEMPLATE/feature_request.md` | Feature request form |
| `ISSUE_TEMPLATE/question.md` | Question form |
| `security-insights.yml` | OpenSSF security insights metadata |
| `zizmor.yml` | Zizmor workflow auditor config |

---

## `internal/`

Developer tooling. Nothing here runs in production.

| File | Purpose |
|---|---|
| `tools/tools.go` | Go pattern for pinning CLI tool versions in `go.mod`. Uses `//go:build tools` so it's never compiled into a binary — just forces `go.mod` to track exact versions of `misspell` and `addlicense`. |
| `tools/sanitycheck.py` | CI formatter. Walks the repo checking every file for: no tabs, no trailing spaces, consistent line endings (LF only), correct indentation per file type. Run in CI to block bad formatting before it merges. |
| `tools/go.mod` / `tools/go.sum` | Go module files for the tools above. |

---

## `pb/`

| File | Purpose |
|---|---|
| `demo.proto` | The single Protobuf schema defining every gRPC service and message type in the demo. This is the source of truth for all inter-service communication. Each service generates its own language-specific stubs from this file at build time. |

### Services defined in `demo.proto`

| Service | What it exposes |
|---|---|
| `CartService` | AddItem, GetCart, EmptyCart |
| `ProductCatalogService` | ListProducts, GetProduct, SearchProducts |
| `ProductReviewService` | GetProductReviews, GetAverageScore, AskProductAIAssistant |
| `CheckoutService` | PlaceOrder |
| `PaymentService` | Charge |
| `ShippingService` | GetQuote, ShipOrder |
| `CurrencyService` | GetSupportedCurrencies, Convert |
| `EmailService` | SendOrderConfirmation |
| `AdService` | GetAds |
| `RecommendationService` | ListRecommendations |
| `FeatureFlagService` | GetFlag, CreateFlag, UpdateFlag, ListFlags, DeleteFlag |

Wire format is **binary Protobuf over HTTP/2** (gRPC) — not JSON or XML. The frontend translates browser REST/JSON calls into gRPC for backend services.

---

## `src/`

Every directory is one service or infrastructure component.

### Business Logic Services

| Service | Language | Role |
|---|---|---|
| `frontend` | TypeScript (Next.js) | Web UI — serves the shop to the browser, translates REST→gRPC for backends |
| `cart` | C# | Stores cart items in Valkey (Redis). Has a chaos mode via `cartFailure` feature flag that routes to a broken store. |
| `checkout` | Go | Orchestrates a full order: calls cart → product-catalog → currency → shipping → payment → email → Kafka |
| `product-catalog` | Go | Serves the product list and search from a JSON file |
| `product-reviews` | Python | Product reviews + AI assistant (calls `llm` service) |
| `recommendation` | Python | Suggests related products |
| `payment` | JavaScript (Node) | Validates and simulates charging a card. Only Visa/MasterCard accepted. Checks `paymentFailure` flag for chaos injection. |
| `shipping` | Rust | Calculates shipping quotes (calls `quote`) and generates tracking IDs |
| `currency` | C++ | Converts between currencies |
| `email` | Ruby | Sends order confirmation emails (simulated) |
| `ad` | Java (Gradle) | Returns contextual ads based on page keywords |
| `quote` | PHP | Generates shipping cost quotes (called by shipping via HTTP) |
| `llm` | Python | LLM-powered AI assistant. Default is a mock; swap in real OpenAI via `.env.override`. |
| `accounting` | C# | Kafka consumer — records orders asynchronously (full stack only) |
| `fraud-detection` | Java (Gradle) | Kafka consumer — flags suspicious orders (full stack only) |

### Infrastructure / Platform

| Directory | Role |
|---|---|
| `frontend-proxy` | Envoy reverse proxy — single entry point on port 8081. Routes by URL path to every service. Has native OTel tracing (every request auto-generates a span) and a fault injection filter used by `imageSlowLoad` feature flag. |
| `load-generator` | Python/Locust — simulates real user traffic. Weighted tasks: browse product (10x), get ads (3x), view cart (3x), checkout (1x), etc. Optionally uses a headless Playwright browser. Sets `synthetic_request=true` baggage so downstream services mark charges as not real. |
| `flagd` | Contains `demo.flagd.json` — the single config file defining every feature flag / chaos scenario. No custom code; uses the open-source flagd binary. |
| `flagd-ui` | Web UI for toggling feature flags live. Accessible at `/feature` through Envoy. |
| `kafka` | Dockerfile wrapping the standard Kafka image with a Java OTel agent baked in. Kafka producer/consumer calls appear in traces automatically. |
| `image-provider` | nginx serving the 10 product JPGs. Exists as a separate service so image requests generate their own spans in traces. |
| `telemetry-docs` | Three-stage Docker build: Weaver generates Markdown from `telemetry-schema/`, mkdocs builds a static site, nginx serves it. Accessible at `/telemetry/`. |
| `react-native-app` | Mobile app version of the shop. No Dockerfile — not part of the Docker Compose stack. |

### Observability Stack (config only, no custom code)

| Directory | Role |
|---|---|
| `otel-collector` | Config files for the OpenTelemetry Collector. Receives all traces/metrics/logs from every service via OTLP and fans out to Jaeger, Prometheus, OpenSearch. |
| `grafana` | Dashboard JSON and datasource provisioning config. |
| `jaeger` | Trace storage and UI config. |
| `prometheus` | Metrics scrape config. |
| `opensearch` | Log storage and index config. |
| `postgresql` | DB init SQL script for the astronomy database used by `product-reviews`. |

---

## `telemetry-schema/`

The formal, machine-readable contract for every custom OTel attribute and metric emitted by the demo. Processed by **Weaver** to generate the docs site at `/telemetry/`.

```
telemetry-schema/
├── manifest.yaml          # Root descriptor — declares semconv version and dependency on OTel standard conventions
├── attributes/            # One file per business domain, defining every custom span attribute
│   ├── ad.yaml            # demo.ad.*
│   ├── cart.yaml          # demo.cart.*
│   ├── exchange.yaml      # demo.exchange.*
│   ├── feature_flag.yaml  # demo.feature_flag.*
│   ├── order.yaml         # demo.order.*
│   ├── payment.yaml       # demo.payment.*
│   ├── product.yaml       # demo.product.*
│   ├── recommendation.yaml
│   ├── request.yaml
│   ├── shipping.yaml      # demo.shipping.*
│   └── user.yaml          # user.id, demo.user_context.*
├── metrics/               # One file per service, defining every metric emitted
│   ├── ad.yaml
│   ├── cart.yaml
│   ├── currency.yaml
│   ├── email.yaml
│   ├── payment.yaml       # demo.payment.transactions counter
│   ├── product_reviews.yaml
│   ├── recommendation.yaml
│   └── shipping.yaml      # demo.shipping.items_shipped counter
└── services/              # Per-service grouping — which attributes belong to which service
    ├── checkout.yaml      # refs: user.id, demo.order.*, demo.payment.*, demo.shipping.*
    ├── payment.yaml
    └── ...
```

Custom attributes use the `demo.*` prefix. Standard OTel attributes (like `user.id`) are referenced via `ref:` from the official semantic conventions at `v1.40.0`.

---

## `test/`

### `test/telemetry/` — Pipeline tests (pytest)

Verifies the *observability infrastructure* is working, not the business logic.

| File | What it tests |
|---|---|
| `conftest.py` | Session-scoped warmup fixture — polls Jaeger, Prometheus, and OpenSearch simultaneously until all three have received data, then unblocks the test suite. Prevents cascading timeouts caused by testing against empty backends. |
| `test_traces.py` | For each service, queries Jaeger API to confirm the service appears and has at least one trace in the last hour. |
| `test_metrics.py` | Queries Prometheus to confirm each service is emitting metrics. |
| `test_logs.py` | Queries OpenSearch to confirm logs are being indexed. |
| `test_collector.py` | Verifies the OTel Collector itself is healthy and accepting data. |
| `test_traces_edges.py` | Verifies parent→child span relationships between services (e.g. frontend→checkout, checkout→payment), proving context propagation works across language boundaries. |
| `services.py` | Defines the service/signal matrix used to parametrize tests by `TEST_SCOPE` (minimal vs. full). |

### `test/tracetesting/` — Trace-based tests (Tracetest)

Makes real gRPC/HTTP calls against live services and asserts on the shape and content of the distributed traces those calls produce. Each YAML file is one test spec.

```
tracetesting/
├── checkout/
│   ├── place-order.yaml       # Fires PlaceOrder gRPC — asserts orderId, shippingTrackingId, and Kafka publish span exist
│   └── add-item-to-cart.yaml
├── payment/
│   ├── valid-credit-card.yaml     # Asserts transactionId returned
│   ├── invalid-credit-card.yaml   # Asserts error span produced
│   ├── expired-credit-card.yaml
│   └── amex-credit-card-not-allowed.yaml
├── cart/                      # Add item, get cart, empty cart scenarios
├── frontend/                  # Full user journey: browse → add to cart → checkout (6 steps)
├── shipping/                  # Quote and ship order scenarios
├── ad/ currency/ email/ product-catalog/ product-reviews/ recommendation/
├── cli-config.yml             # Tracetest CLI config
├── tracetest-config.yaml      # Tracetest server connection config
└── tracetest-provision.yaml   # Tracetest environment provisioning
```

The selector syntax queries traces like a database:
```yaml
selector: span[tracetest.span.type="messaging" name="orders publish" messaging.system="kafka"]
```
If the expected span doesn't exist in the trace, the test fails — even if the user-visible result was correct.

---

## Root Files

### Compose Files

| File | Purpose |
|---|---|
| `compose.yaml` | Core services — all business logic services + flagd + image-provider + otel-collector. The base layer always loaded first. |
| `compose.full.yaml` | Override adding Kafka, `accounting`, and `fraud-detection`. Also patches `checkout` to connect to Kafka and `otel-collector` to scrape Kafka metrics. |
| `compose.observability.yaml` | Override adding `grafana`, `jaeger`, `prometheus`, `opensearch`. Required for Envoy to reach all its configured clusters and exit `PRE_INITIALIZING`. |
| `compose.profiling.yaml` | Override adding `firepit` (continuous profiling UI) and the eBPF profiler. |
| `compose.extras.yaml` | Intentionally empty. A stable extension point for forks to add their own backends without touching upstream files. Always loaded last. |
| `compose.tests.yaml` | Test runner services (Tracetest, frontend test runner). Used only by `make run-tests`. |

**Canonical start command (via Makefile):**
```bash
make start          # full: core + Kafka + observability + extras
make start-minimal  # core + observability only (no Kafka)
make stop           # tears down all stacks
```

### `.env` and `.env.override`

`.env` is the master config: every port, hostname, image version, and Dockerfile path for all services. Committed to the repo.

`.env.override` is gitignored personal overrides. Primary use: swap in a real OpenAI-compatible LLM:
```bash
LLM_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini
OPENAI_API_KEY=<your key>
```

### `Makefile`

The developer command center. Key targets beyond start/stop:

| Target | What it does |
|---|---|
| `make build service=frontend` | Build a single service image |
| `make restart service=cart` | Stop, remove, recreate, start one container |
| `make redeploy service=checkout` | Rebuild image then restart |
| `make generate-protobuf` | Regenerate language stubs from `pb/demo.proto` locally |
| `make docker-generate-protobuf` | Same but inside Docker (no local tooling needed) |
| `make check` | All linting: misspell + markdownlint + license headers + link checker |
| `make fix` | Auto-fix misspellings |
| `make addlicense` | Auto-add missing Apache license headers |
| `make run-telemetry-tests` | Start full stack, run pipeline tests, stop |
| `make build-multiplatform` | Build linux/amd64 + linux/arm64 images via buildx |

### Proto Generation Scripts

| Script | Purpose |
|---|---|
| `ide-gen-proto.sh` | Regenerates all language stubs from `pb/demo.proto` using locally installed `protoc` |
| `docker-gen-proto.sh` | Same but spins up a Docker container with protoc — no local tooling required |

Generated files land in: `src/checkout/genproto/`, `src/product-catalog/genproto/`, `src/recommendation/demo_pb2.py`, `src/frontend/protos/demo.ts`, etc.

### Config Files

| File | Purpose |
|---|---|
| `otel-config.yml` | Declarative OTel SDK config (File Configuration spec). Services that support it point here instead of configuring traces/metrics/logs in code. Sets up OTLP gRPC exporters, W3C TraceContext + Baggage propagators, and resource detectors. |
| `buildkitd.toml` | Caps Docker BuildKit parallelism to 4 concurrent service builds to avoid saturating the machine during `make build`. |

### Linting and Git Files

| File | Purpose |
|---|---|
| `.licenserc.json` | Defines the exact license header format required per file type (Go, Python, Java, PHP, SQL, YAML, shell, Dockerfile) — enforced by `addlicense` in CI. |
| `.lychee.toml` | Link checker config. Excludes localhost, Google Calendar, OpenAI URLs (they 403 bots). Max 1 concurrent request to avoid rate limits. |
| `.markdownlint.yaml` | Markdown formatting rules for all `.md` files. |
| `.yamllint` / `.yamlignore` | YAML formatting rules and files to skip. |
| `.dockerignore` | Excludes `node_modules`, `.venv`, `build/`, `.gradle/`, all JPGs/PNGs from Docker build contexts. Keeps image builds fast and lean. |
| `.gitignore` | Excludes IDE folders (`.idea/`, `.vscode/`), build artifacts, AI tool configs (`.claude/`, `.cursor/`, `.codex/`), and generated proto copies. |
| `.gitattributes` | Forces LF line endings globally (`* text=auto`) and explicitly for `gradlew` to prevent Windows CRLF breaking the Gradle shell script. |

### Documentation

| File | Purpose |
|---|---|
| `README.md` | Quick start, architecture diagram, links to all UIs. |
| `CONTRIBUTING.md` | Dev environment setup, PR requirements, coding standards. |
| `AGENTS.md` | Rules for AI-assisted contributions: no AI-generated issue/PR comments, disclose AI use in commits via `Assisted-by:` trailer (not `Co-authored-by:`). |
| `CLAUDE.md` | Loads `AGENTS.md` into Claude Code's context. |
| `CHANGELOG.md` | Version history. |
| `LICENSE` | Apache 2.0. |

### Node / npm

`package.json` and `package-lock.json` exist only at the root to install `markdownlint-cli` for the `make markdownlint` target. Not related to the frontend Next.js app (which has its own `package.json` in `src/frontend/`).

---

## Feature Flags (Chaos Scenarios)

All flags are defined in `src/flagd/demo.flagd.json` and default to `off`. Toggle via the flagd-ui at `/feature`.

| Flag | Effect |
|---|---|
| `cartFailure` | Cart EmptyCart routes to a broken store |
| `paymentFailure` | Payment fails at 10/25/50/75/90/100% rate |
| `paymentUnreachable` | Checkout points payment at a non-existent address |
| `productCatalogFailure` | Fails requests for product OLJCESPC7Z |
| `recommendationCacheFailure` | Breaks recommendation caching |
| `adHighCpu` / `adManualGc` / `adFailure` | Three chaos modes for the Java ad service |
| `kafkaQueueProblems` | Floods Kafka with 100 duplicate messages, causes consumer lag |
| `emailMemoryLeak` | Allocates 1x–10000x memory per email until OOM |
| `imageSlowLoad` | Delays images 5 or 10 seconds via Envoy fault injection |
| `intlShippingSlowdown` | Slows shipping responses 5 or 10 seconds |
| `loadGeneratorFloodHomepage` | Load generator hits homepage 100x per task |
| `llmInaccurateResponse` | LLM returns wrong summary for product L9ECAV7KIM |
| `llmRateLimitError` | LLM intermittently returns rate limit errors |
| `failedReadinessProbe` | Cart fails its Kubernetes readiness probe |

---

## OTel Instrumentation Pattern

Every service follows the same pattern regardless of language:

1. On startup: initialize TracerProvider, MeterProvider, LoggerProvider — all exporting to the OTel Collector via OTLP gRPC
2. On every operation: get the current span from context, add business-relevant attributes (`user.id`, `product.id`, etc.), record errors onto the span
3. Propagate trace context downstream via W3C `traceparent` header (HTTP) or Kafka message headers

This is what makes a single user request visible as one connected trace across TypeScript → Go → Rust → C++ → JavaScript in Jaeger.
