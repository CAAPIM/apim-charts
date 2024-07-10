#!/bin/bash
set -euo pipefail

sh "helm plugin install https://github.com/helm-unittest/helm-unittest.git > /dev/null 2>&1"
sh "cd apim-charts/charts/portal; helm unittest ."
