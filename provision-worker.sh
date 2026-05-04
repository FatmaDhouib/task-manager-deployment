#!/bin/bash
# provision-worker.sh

echo "=========================================="
echo "Provisioning Worker Node"
echo "=========================================="

# Wait for master to be ready and token to be available
echo "Waiting for master node token..."
while [ ! -f /vagrant/node-token ]; do
  echo "Waiting for node-token from master..."
  sleep 5
done

# Get token from shared folder
TOKEN=$(cat /vagrant/node-token)

# Install K3s worker
echo "Installing K3s worker and joining cluster..."
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.27.10+k3s2" \
  K3S_URL=https://192.168.56.10:6443 \
  K3S_TOKEN=$TOKEN \
  sh -

echo "Worker has joined the cluster!"
echo "✅ WORKER PROVISIONING COMPLETE!"