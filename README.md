# docket-terraform-modules

Reusable Terraform modules for the Docket platform, versioned by tag.

This repository holds the **blueprints**. The live infrastructure that builds
from them is in
[docket-infrastructure](https://github.com/sintratel-docket-platform/docket-infrastructure),
which pins a version of each module rather than consuming it by path.

## Why it is public

`terraform init` has to clone this repository from CI. A private one would need
a static credential in the pipeline, which is exactly what
[ADR-011](https://github.com/sintratel-docket-platform/docket-architecture/blob/main/decisions.md)
avoids by using OIDC. Public keeps the "no long-lived keys" posture intact.

That makes one rule absolute: **nothing internal may ever land here.** No
account identifier, no account-qualified ARN, no domain, no named principal, no
credential. The `exposure` job in `module-ci.yml` fails the build on any of
them, and git history is public too, so a leak needs history rewriting rather
than a follow-up commit.

The modules name nothing after this project. Every one takes a `name_prefix`,
so what they create is the caller's to decide.

## Modules

Also indexed, with the same table, in [`modules/README.md`](modules/README.md).

| Module | Responsibility |
|---|---|
| [`network`](modules/network) | VPC, subnets, Internet Gateway, NAT Gateway, route tables, security groups |
| [`cluster`](modules/cluster) | EKS cluster, node group, add-ons, OIDC provider, access entries |
| [`namespace`](modules/namespace) | One environment inside a cluster: namespace, quotas, RBAC, network policies |
| [`irsa`](modules/irsa) | IAM role assumable by one specific ServiceAccount in one specific namespace |
| [`registry`](modules/registry) | ECR repositories and their lifecycle policy |
| [`ci-identity`](modules/ci-identity) | GitHub OIDC provider and the roles the pipeline assumes |
| [`environment`](modules/environment) | SSM parameter tree for one environment |
| [`dns`](modules/dns) | Route 53 hosted zone and ACM certificate |

## Consuming a module

Always by tag. A branch reference on `main` means the consumer tracks a moving
target, and promotion between environments stops meaning anything.

```hcl
module "network" {
  source = "git::https://github.com/sintratel-docket-platform/docket-terraform-modules.git//modules/network?ref=v1.0.0"

  name_prefix          = "docket-ephemeral"
  cluster_name         = "docket-eks"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

Changing `source` does not change any resource address: the address comes from
the `module` block name. Repointing needs no `moved` block; renaming the block
does.

## Versioning

Tags are repository-wide: `v1.1.0` versions all eight modules together. That is
the accepted trade-off of a modules monorepo and is fine at this size. If the
modules start releasing at visibly different cadences, the answer is component
tags (`network/v1.2.0`), not more repositories.

Releases are automatic, from the Conventional Commits (ADR-013 in
`docket-architecture`):

1. A pull request that changes a module merges into `main`.
2. `.github/workflows/release.yml` runs release-please, which reads the commits
   that touched `modules/` since the last release. A `feat` bumps the minor, a
   `fix` or `perf` the patch, and `!` or a `BREAKING CHANGE:` footer the major.
   Anything else, and any change outside `modules/`, releases nothing.
3. It opens, or updates, a single release pull request titled
   `chore: release X.Y.Z`, carrying the changelog.
4. A person approves and merges it. Merging creates the `vX.Y.Z` tag. That is
   the deliberate step: several module changes can wait in one release.
5. Renovate, in `docket-infrastructure`, opens a pull request per stack moving
   `?ref=` to the new tag, never for production. A person reviews its plan,
   merges it and applies.

Tags are immutable: a ruleset blocks deleting, moving or force-updating
`refs/tags/v*`. The last released version lives in
`.release-please-manifest.json`, and `release-please-config.json` holds the
rest of the setup. Never create a `v*` tag by hand; it would put a version in
the history that the release pull request does not know about.

## Working on a module

```bash
cd modules/<name>
terraform init -backend=false
terraform validate
terraform test          # where a tests/ directory exists
```

While a change is in flight, a consumer may point at the branch. Before the
consumer's pull request merges, that reference has to become a tag.

## Checks

Every pull request runs: the exposure scan, `fmt` and `validate` per module,
TFLint, Trivy, Checkov, `terraform test`, and a `terraform-docs` diff so a
published module's README cannot go stale.

## Contributing

[`CONTRIBUTING.md`](CONTRIBUTING.md) is the short, repository-local form of
[`AGENTS.md`](https://github.com/sintratel-docket-platform/docket-architecture/blob/main/standards/AGENTS.md),
which is normative. Pull requests follow
[`.github/pull_request_template.md`](.github/pull_request_template.md).
