#!/bin/bash
set -e

CHART_PATH=${1:-"./charts/opencode"}

echo "Linting Helm chart: $CHART_PATH"
helm lint "$CHART_PATH"

echo "Templating Helm chart: $CHART_PATH"
helm template "$CHART_PATH" > /dev/null

echo "Helm tests (dry-run/lint) passed for $CHART_PATH"
