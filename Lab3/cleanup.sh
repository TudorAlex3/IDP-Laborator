#!/bin/bash
# Cleanup script for Lab 3

echo "=== Cleanup Lab 3 ==="

echo "Removing Docker stack..."
docker stack rm lab3 2>/dev/null

echo "Waiting for services to stop..."
sleep 5

echo "Stopping and removing NFS container..."
docker stop nfs 2>/dev/null
docker rm nfs 2>/dev/null

echo "Removing NFS volume..."
docker volume rm mynfsvol 2>/dev/null

echo "Removing unused volumes..."
docker volume prune -f

echo "General cleanup..."
docker system prune -f

echo "=== Cleanup complete! ==="
