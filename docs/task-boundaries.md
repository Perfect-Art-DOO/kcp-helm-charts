# Task Boundaries

## Tasks That Belong Here

- create, update, or patch Helm chart templates;
- change chart defaults, schema, helpers, or packaging metadata;
- maintain internal charts and curated forks of upstream charts;
- publish new chart versions and update chart repository index files.

## Tasks That Do Not Belong Here

- editing environment-specific `values.yaml` for a deployed service;
- provisioning infrastructure or bootstrapping the cluster;
- declaring Argo CD applications and stage ordering;
- implementing CI/CD workflow logic;
- storing application source code.

## Routing Guide

- If the bug is in templates, helpers, default values, or packaged chart contents, it belongs here.
- If the chart is fine and only `values.yaml` must change, go to a GitOps values repository.
- If the chart source is referenced from an Argo CD application and that declaration must change, go to `kcp-infrastructure-system` or `kcp-infrastructure-management`.
- If deploy automation updates the wrong values after build, go to `kcp-deployment`.

## Guardrails

- do not put environment-specific secrets or app values here;
- do not turn this repository into an orchestration or GitOps state repo;
- do not use chart changes as a substitute for fixing wrong tenant or environment values elsewhere.
