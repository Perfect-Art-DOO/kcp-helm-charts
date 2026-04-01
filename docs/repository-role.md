# Repository Role

## Purpose

`kcp-helm-charts` is the reusable chart implementation repository for the KCP platform.

It contains internal charts, curated forks, and chart packaging metadata that are consumed by Argo CD applications in other repositories.

## Why This Repository Exists

- to keep deployable chart logic in one place;
- to avoid duplicating templates across environment and orchestration repositories;
- to allow the platform to patch or extend upstream charts without hiding those changes inside values files.

## Source Of Truth In This Repository

- chart source directories such as `uniDeploy`, `cnpgcluster`, `mcp-stack`, and `zally`;
- `index.yaml` and packaging metadata for published chart artifacts;
- chart-specific README and changelog files.

## High-Level Goal

This repository provides the reusable deployment building blocks that other repositories compose with environment values and orchestration logic.

## Success Looks Like

- chart logic is reusable across environments and workloads;
- environment-specific configuration stays outside chart templates;
- platform-specific customizations are reviewed once and reused many times;
- Argo CD applications can consume stable chart versions from one chart source.
