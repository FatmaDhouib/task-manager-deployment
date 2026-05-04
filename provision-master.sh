#!/bin/bash
# provision-master.sh

echo "=========================================="
echo "Provisioning Master Node"
echo "=========================================="

# Install K3s master
echo "Installing K3s master..."
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.27.10+k3s2" \
  K3S_KUBECONFIG_MODE="644" \
  INSTALL_K3S_EXEC="server --bind-address=192.168.56.10 --advertise-address=192.168.56.10" \
  sh -

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 30

# Get node token and save to shared folder
echo "Saving node token for workers..."
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

# Setup kubeconfig for vagrant user
echo "Setting up kubeconfig..."
mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
sed -i 's/127.0.0.1/192.168.56.10/g' /home/vagrant/.kube/config

# Export kubeconfig for current session
export KUBECONFIG=/home/vagrant/.kube/config

# Verify cluster is working
echo "Verifying cluster..."
kubectl get nodes

# Deploy Task Manager application
echo "=========================================="
echo "Deploying Task Manager Application"
echo "=========================================="

cd /vagrant

# Create namespace
kubectl create namespace task-manager 2>/dev/null || true

# Apply configurations
kubectl apply -f k8s-deployments/secrets.yaml
kubectl apply -f k8s-deployments/configmaps/

# Deploy PostgreSQL
kubectl apply -f k8s-deployments/deployments/postgres-statefulset.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 20
kubectl wait --for=condition=ready pod -l app=postgres -n task-manager --timeout=120s 2>/dev/null || true

# Deploy backend and frontend
kubectl apply -f k8s-deployments/deployments/backend-deployment.yaml
kubectl apply -f k8s-deployments/deployments/frontend-deployment.yaml

# Optional components (ignore errors if files don't exist)
kubectl apply -f k8s-deployments/hpa/ 2>/dev/null || true
kubectl apply -f k8s-deployments/ingress/ 2>/dev/null || true
kubectl apply -f k8s-deployments/networkpolicy/ 2>/dev/null || true

# Wait for all pods
echo "Waiting for application pods..."
sleep 15
kubectl wait --for=condition=ready pod -l app=backend -n task-manager --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=frontend -n task-manager --timeout=60s 2>/dev/null || true

# Show deployment status
echo ""
echo "=========================================="
echo "Pod Status:"
kubectl get pods -n task-manager
echo "=========================================="
echo ""
echo "✅ MASTER PROVISIONING COMPLETE!"
echo "=========================================="
echo "Task Manager is deployed and available at:"
echo "http://192.168.56.10:30080"
echo "=========================================="