#!/bin/bash
set -euxo pipefail

helm repo add hazelcast "https://hazelcast-charts.s3.amazonaws.com/"
helm repo add ingress-nginx "https://kubernetes.github.io/ingress-nginx/"