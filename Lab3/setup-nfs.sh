#!/bin/bash
# Setup script for NFS Server

echo "=== Setup NFS Server ==="
mkdir -p /tmp/nfs-share/database/data /tmp/nfs-share/database/config
docker run -d --name nfs --privileged \
    -v /tmp/nfs-share:/nfsshare \
    -e SHARED_DIRECTORY=/nfsshare \
    itsthenetwork/nfs-server-alpine:latest
echo "NFS Server started!"
echo "Creating NFS volume..."
NFS_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nfs)
docker volume create --driver local \
    --opt type=nfs \
    --opt o=nfsvers=3,addr=${NFS_IP},rw \
    --opt device=:/nfsshare \
    mynfsvol
echo "NFS volume created! Server IP: ${NFS_IP}"
docker volume inspect mynfsvol
