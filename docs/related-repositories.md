# Related Repositories

## kcp-infrastructure-system

- Role: cluster bootstrap and shared service orchestration.
- Why linked: it declares many Argo CD applications that consume charts from this repository.
- Go there when: the application declaration, sync order, or cluster bootstrap flow must change.
- Do not go there when: the chart template itself is wrong.

## kcp-infrastructure-management

- Role: tenant/project orchestration.
- Why linked: it deploys tenant and project workloads using charts from this repository.
- Go there when: the tenant/project application declaration or lifecycle logic must change.
- Do not go there when: only reusable chart logic must change.

## kcp-dev-apps-configs

- Role: `dev` values for non-system services.
- Why linked: those values customize charts from this repository.
- Go there when: only `dev` app values must change.
- Do not go there when: the chart template or chart defaults are wrong.

## kcp-kubernetes-system-tools

- Role: GitOps content for system-side and selected platform workloads.
- Why linked: it stores values and manifests that are often paired with charts from this repository.
- Go there when: the issue is in environment-specific system values or manifests.
- Do not go there when: the issue is in reusable chart implementation.
