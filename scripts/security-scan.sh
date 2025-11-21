#!/bin/bash
# Security scan with Trivy

set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image-name:tag>"
  exit 1
fi

IMAGE="$1"
SEVERITY="${SEVERITY:-HIGH,CRITICAL}"
EXIT_CODE="${EXIT_CODE:-0}"

echo "Running security scan on $IMAGE..."
echo "Severity threshold: $SEVERITY"
echo "Exit code on findings: $EXIT_CODE"

trivy image --exit-code "$EXIT_CODE" --severity "$SEVERITY" "$IMAGE"

echo "✅ Security scan completed"

