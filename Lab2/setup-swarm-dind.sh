#!/bin/bash
# Setup script for Docker Swarm cluster with dind (Docker-in-Docker)

echo "=== 1. Initialize Swarm on local machine (manager) ==="
docker swarm init 2>/dev/null || echo "Swarm already initialized"

echo ""
echo "=== 2. Save manager token and IP ==="
SWARM_TOKEN=$(docker swarm join-token -q worker)
SWARM_MASTER_IP=$(docker info --format '{{.Swarm.NodeAddr}}')
echo "Worker token: $SWARM_TOKEN"
echo "Manager IP: $SWARM_MASTER_IP"

echo ""
echo "=== 3. Configure variables ==="
DOCKER_VERSION=29.3.0-dind
NUM_WORKERS=3
echo "dind version: $DOCKER_VERSION"
echo "Number of workers: $NUM_WORKERS"

echo ""
echo "=== 4. Create worker containers (dind) ==="
for i in $(seq "${NUM_WORKERS}"); do
    echo "Starting worker-${i}..."
    docker run -d --privileged \
        --name worker-${i} \
        --hostname=worker-${i} \
        -p ${i}2375:2375 \
        docker:${DOCKER_VERSION}
done

echo ""
echo "=== 5. Waiting for workers to start (10 seconds) ==="
sleep 10

echo ""
echo "=== 6. Join workers to Swarm ==="
for i in $(seq "${NUM_WORKERS}"); do
    echo "Joining worker-${i}..."
    docker exec -it worker-${i} docker swarm join --token ${SWARM_TOKEN} ${SWARM_MASTER_IP}:2377
done

echo ""
echo "=== 7. Verify cluster ==="
docker node ls

echo ""
echo "=== DONE! Swarm cluster with ${NUM_WORKERS} workers + 1 manager ==="
echo ""
echo "Useful commands:"
echo "  docker node ls                                    # list nodes"
echo "  docker stack deploy -c docker-compose.swarm.yml lab2  # deploy stack"
echo "  docker stack ps lab2                              # list tasks"
echo "  docker service ls                                 # list services"
echo ""
echo "Cleanup:"
echo "  docker stack rm lab2                              # remove stack"
echo "  docker stop worker-1 worker-2 worker-3           # stop workers"
echo "  docker rm worker-1 worker-2 worker-3             # remove workers"
echo "  docker swarm leave --force                        # leave swarm"
