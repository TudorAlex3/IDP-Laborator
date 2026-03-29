#!/bin/bash
# Cleanup script for Lab 4

echo "=== Cleanup Lab 4 ==="

echo "Removing Portainer stack..."
docker stack rm portainer 2>/dev/null

echo "Removing app stack..."
docker stack rm lab4 2>/dev/null

echo "Waiting for services to stop..."
sleep 5

echo "Stopping GitLab Runner..."
docker stop gitlab-runner 2>/dev/null
docker rm gitlab-runner 2>/dev/null

echo "Docker Compose down..."
docker compose down -v 2>/dev/null

echo "General cleanup..."
docker system prune -f

echo "=== Cleanup complete! ==="
