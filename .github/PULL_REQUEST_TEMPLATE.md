# Related Issue
<!-- Link to the issue this PR is resolving. Example: Fixes #123 -->
Fixes #

# Changes
Please provide a brief description of the changes here.

## Type of Change
<!-- Please delete options that are not relevant. -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Chore (refactoring, dependency updates, etc.)

# Testing
<!-- Describe the tests that you ran to verify your changes. -->

## Checklist

For any significant contributions, please make sure you have completed the following
essential items:

* [ ] `CHANGELOG.md` updated to document new feature additions
* [ ] Appropriate documentation updates in the [docs][]
* [ ] Appropriate Helm chart updates in the [helm-charts][]
* [ ] I have performed a self-review of my code
* [ ] I have added/updated tests that prove my fix is effective or that my feature works

<!--
A Pull Request that modifies instrumentation code will likely require an
update in docs. Please make sure to update the opentelemetry.io repo with any
docs changes.

A Pull Request that modifies compose*.yaml, otelcol-config*.yml, or
Grafana dashboards will likely require an update to the Demo Helm chart.
Other changes affecting how a service is deployed will also likely require an
update to the Demo Helm chart.
-->

Maintainers will not merge until the above have been completed. If you're unsure
which docs need to be changed ping the
[@open-telemetry/demo-approvers](https://github.com/orgs/open-telemetry/teams/demo-approvers).

[docs]: https://opentelemetry.io/docs/demo/
[helm-charts]: https://github.com/open-telemetry/opentelemetry-helm-charts
