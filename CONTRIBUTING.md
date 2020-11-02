# Contributing to the APIM Helm Charts

Contributions are welcome via GitHub Pull Requests. All PRs should be submitted against the ***unstable*** branch, where they will undergo review by a Broadcom APIM team member.

## How to Contribute

***Note: *** Raising PRs against one Chart at a time will speed up the release process.

1. Fork this repository, develop, and test your changes.
2. Submit a pull request against the ***unstable*** branch.

### Technical Requirements

When submitting a PR make sure that it:
- Must pass internal application testing and GitHub CI jobs for linting and different k8s platforms (Managed by Broadcom and Github Actions).
- Implement changes in both files if the chart contains a _values-production.yaml_ and a _values.yaml_.
- Any change to a chart requires a version bump following [semver](https://semver.org/).

### Documentation Requirements

- A chart's `README.md` must include any additional configuration options.
- The title of the PR starts with chart name (e.g. `[charts/gateway]`)

### PR Approval and Release Process

***Note:*** Check/Raise a bug feature request first, this will save you time if there's something that's already known/in progress.

1. Changes are automatically linted and tested using the [`ct` tool](https://github.com/helm/chart-testing) as a [GitHub action](https://github.com/helm/chart-testing-action). Those tests are based on `helm lint` and `kubeval`
2. Changes are manually reviewed by Broadcom APIM team members.
3. Once the changes are accepted, the PR is tested (if needed) into the Broadcom CI pipeline, the chart is installed and tested (verification and functional tests).
4. When the PR passes all tests, the PR is merged by the reviewer(s) in the GitHub `master` branch.
5. On merge, the Chart is pushed to the layer7 Chart Repository

**Tips:**
* A description. What did you expect to happen? What actually happened? Why do you think the behavior was incorrect?
* Provide any logs or relevant output.
* What version are you running when reproducing issue? What was the last version that the feature worked?
* Anything else that seems relevant.
