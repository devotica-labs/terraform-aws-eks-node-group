# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Releases are cut automatically by `release-please` on merge to `main`,
driven by Conventional Commit prefixes (`feat:` → minor, `fix:`/`docs:`/`chore:` → patch,
`feat!:` or `BREAKING CHANGE:` footer → major).

## 0.1.0 (2026-06-24)


### Features

* native EKS managed node group (fintech-hardened, cloudposse-standard) ([6d9cecd](https://github.com/devotica-labs/terraform-aws-eks-node-group/commit/6d9cecdf4b89154883d77f4fe0be01aac0ad3590))

## [Unreleased]

### Added
- Initial module — a native (no external module dependencies) EKS **managed
  node group**:
  - Attaches to an existing EKS cluster; resolves the Kubernetes version from
    the cluster unless one is given.
  - A hardened launch template: encrypted gp3 root volume (AWS or customer
    KMS key), IMDSv2 required with hop limit 1 (containers blocked from IMDS),
    detailed monitoring, EBS-optimized.
  - IAM node role (create or bring-your-own) with the standard worker policies
    plus `AmazonSSMManagedInstanceCore` (Session Manager instead of SSH).
  - Graviton defaults (`t4g.large` on `AL2023_ARM_64_STANDARD`), on-demand or
    spot capacity, labels + taints, rolling-update bounds, and
    `desired_size` ignored after create (for the cluster autoscaler).
- First module built to the **cloudposse module standard, implemented
  natively**: README.yaml-driven docs, the
  `enabled`/`namespace`/`environment`/`stage`/`name`/`attributes`/`tags`/`label_order`
  label surface (in `label.tf`, no null-label dependency), `examples/complete`,
  and Makefile targets.
- `examples/basic` + `examples/complete`, and unit/contract/integration
  `terraform test` suites.

### Deferred to later versions
- Bottlerocket / Windows / AL2 multi-OS userdata bootstrap options.
- create-before-destroy node-group replacement strategy.
- A `sample-infra/eks-nodes` consumer service.
