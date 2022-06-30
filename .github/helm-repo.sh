#!/bin/bash
set -euxo pipefail

helm repo add hazelcast "https://hazelcast-charts.s3.amazonaws.com/"
helm repo add influx "https://helm.influxdata.com/"
helm repo add bitnami "https://charts.bitnami.com/bitnami"
helm repo add stable "https://charts.helm.sh/stable"
helm repo add ingress-nginx "https://kubernetes.github.io/ingress-nginx/"