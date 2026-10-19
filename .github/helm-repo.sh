#!/bin/bash
# Copyright (c) 2026 Broadcom Inc. and its subsidiaries. All Rights Reserved.
set -euxo pipefail

helm repo add hazelcast "https://hazelcast-charts.s3.amazonaws.com/"
helm repo add contour "https://projectcontour.github.io/helm-charts/"
