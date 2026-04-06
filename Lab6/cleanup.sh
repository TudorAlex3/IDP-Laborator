#!/bin/bash
# Cleanup script for Lab 6

echo "=== Cleanup Lab 6 ==="

echo "Deleting all resources..."
kubectl delete all --all 2>/dev/null
kubectl delete configmap --all 2>/dev/null
kubectl delete secret --field-selector type!=kubernetes.io/service-account-token --all 2>/dev/null
kubectl delete namespace demo-ns 2>/dev/null

echo "Deleting kind cluster..."
kind delete cluster

echo "=== Cleanup complete! ==="
