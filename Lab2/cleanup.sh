#!/bin/bash
# Cleanup script for Lab 2

echo "=== Cleanup Lab 2 ==="

echo "1. Removing stack (if exists)..."
docker stack rm lab2 2>/dev/null

echo "2. Waiting for services to stop (5 seconds)..."
sleep 5

echo "3. Stopping and removing dind worker containers..."
for i in 1 2 3; do
    docker stop worker-${i} 2>/dev/null
    docker rm worker-${i} 2>/dev/null
done

echo "4. Leaving Swarm..."
docker swarm leave --force 2>/dev/null

echo "5. Docker Compose down..."
docker compose down -v 2>/dev/null

echo "6. General cleanup..."
docker system prune -f

echo ""
echo "=== Cleanup complete! ==="
