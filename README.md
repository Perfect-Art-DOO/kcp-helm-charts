# The Chart Repository

## Charts

| chart | helm version | original repo |
|---|---|---|
| uniDeploy | 0.1.3 ||
| cert-manager | v1.10.1 | https://charts.jetstack.io |
| ingress-nginx | 4.5.2 | https://kubernetes.github.io/ingress-nginx |
| k8s-ephemeral-storage-metrics | 1.0.0 | https://github.com/jmcgrath207/k8s-ephemeral-storage-metrics |
| kube-prometheus-stack | 43.2.0 | https://prometheus-community.github.io/helm-charts |
| prometheus-blackbox-exporter | 7.6.1 | https://prometheus-community.github.io/helm-charts |
| loki-stack | 2.8.9 | https://grafana.github.io/helm-charts |
| pushprox | 0.1.4 | https://devopstales.github.io/helm-charts |
| redis | 14.6.3 | https://github.com/bitnami/charts/tree/main/bitnami/redis |
| goldilocks | 6.5.5 | https://github.com/FairwindsOps/charts/tree/master/stable/goldilocks |
| vertical-pod-autoscaler | 7.0.1 | https://github.com/cowboysysop/charts/tree/master/charts/vertical-pod-autoscaler |
| sealed-secrets | 2.9.0 | https://github.com/bitnami-labs/sealed-secrets |
| kubeshark | 40.5 | https://github.com/kubeshark/kubeshark/tree/master/helm-chart |
| k8s-event-logger | 1.1.4 | k8s-event-logger-1.1.4.tgz |
|

## How to use

- Add github page
```bash
helm repo add movos-ag_charts https://movos-ag.github.io/helm-charts
```
## How to add chart
1. download chart tgz to repository
```bash
helm pull <repo>/<chart>
```
2. index repo
```bash
helm repo index .
```
3. add changes to README.md
