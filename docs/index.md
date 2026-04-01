# kcp-helm-charts

## Read Next

- [Repository Role](repository-role.md)
- [Task Boundaries](task-boundaries.md)
- [Related Repositories](related-repositories.md)

## Role

`kcp-helm-charts` is the internal Helm chart repository for KCP deployments.

Its purpose is to publish reusable charts and forks/customizations that are consumed by Argo CD applications across the platform.

## What This Repository Owns

- custom and curated Helm charts such as `uniDeploy`, `cnpgcluster`, and `oauth-proxy-httproute-keycloak`;
- chart packaging metadata and published chart index;
- organization-specific chart modifications that should not live only in inline Argo CD values.

## What This Repository Does Not Own

- environment-specific values for individual apps;
- tenant/project orchestration logic;
- cluster provisioning;
- shared system manifests stored as plain Kubernetes YAML or Kustomize overlays.

## Depends On

- upstream Helm charts when a chart is forked or repackaged;
- GitHub Pages publishing for chart distribution.

## Used By

- `kcp-infrastructure-system`, which references this chart repository from cluster-wide Argo CD applications;
- `kcp-infrastructure-management`, which references this chart repository from tenant/project Argo CD applications;
- `kcp-dev-apps-configs`, whose values are applied to charts from this repository.

## Related Repositories

- `kcp-infrastructure-system`: installs shared system services using charts from this repository.
- `kcp-infrastructure-management`: installs tenant/project workloads using charts from this repository.
- `kcp-dev-apps-configs`: supplies values for charts such as `uniDeploy`.

## Boundary

This repository is the source of truth for reusable Helm chart implementation.

It should not hold per-environment app values or infrastructure orchestration flow.
