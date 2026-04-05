#!/bin/bash
# Cleanup script for Lab 5

echo "=== Cleanup Lab 5 ==="

echo "Removing stack..."
docker stack rm prom 2>/dev/null

echo "Waiting for services to stop..."
sleep 10

echo "Removing Loki plugin..."
docker plugin rm loki --force 2>/dev/null

echo "General cleanup..."
docker system prune -f

echo "=== Cleanup complete! ==="
