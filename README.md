# Task Manager Application - Kubernetes Deployment

A complete Kubernetes deployment solution for a Task Manager application using K3s, featuring a Node.js backend, frontend, and PostgreSQL database with automated infrastructure provisioning via Vagrant and Ansible.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Kubernetes Resources](#kubernetes-resources)
- [Deployment & Scaling](#deployment--scaling)
- [Network Policies](#network-policies)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

---

## 🎯 Overview

This project provides:
- **3-node Kubernetes cluster** (1 master + 2 workers) via Vagrant
- **Task Manager application** with backend API and frontend UI
- **PostgreSQL database** with persistent storage
- **Auto-scaling** with Horizontal Pod Autoscaler (HPA)
- **Network segmentation** with Kubernetes NetworkPolicies
- **Automated provisioning** with Ansible playbooks
- **Ingress routing** for multi-service access

### Tech Stack
- **K3s**: Lightweight Kubernetes distribution
- **Container Runtime**: containerd (via K3s)
- **Database**: PostgreSQL 16-alpine
- **Backend**: Node.js application (port 3000)
- **Frontend**: Web application (port 80)
- **Infrastructure**: Vagrant + VirtualBox
- **Configuration Management**: Ansible

---

## 🏗️ Architecture

### Cluster Topology
```
┌─────────────────────────────────────────┐
│         Vagrant VirtualBox              │
├─────────────────────────────────────────┤
│  Master (192.168.56.10)                │
│  └─ K3s Server                         │
│  └─ 2GB RAM, 2 CPUs                    │
│                                         │
│  Worker1 (192.168.56.11)               │
│  └─ K3s Agent                          │
│  └─ 2GB RAM, 1 CPU                     │
│                                         │
│  Worker2 (192.168.56.12)               │
│  └─ K3s Agent                          │
│  └─ 2GB RAM, 1 CPU                     │
└─────────────────────────────────────────┘
```

### Application Components
```
task-manager namespace:
├── Frontend Pod (x2, HPA: 2-5)
│   └─ Image: fatmadhouib/taskmanager-frontend:v2
│   └─ Port: 80
│   └─ NodePort: 30080
│
├── Backend Pod (x2, HPA: 2-5)
│   └─ Image: fatmadhouib/taskmanager-backend:v2
│   └─ Port: 3000
│   └─ ConfigMap: backend-config
│   └─ Secret: postgres-secrets
│
└── PostgreSQL Pod (x1)
    └─ Image: postgres:16-alpine
    └─ Storage: 5Gi PVC
    └─ InitDB: SQL scripts from ConfigMap
```

---

## 📦 Prerequisites

### System Requirements
- **Host OS**: Windows, macOS, or Linux
- **Virtualization**: VirtualBox 6.1+
- **Vagrant**: 2.2.0+
- **Disk Space**: 20GB (for 3 VMs)
- **RAM**: 8GB minimum (6GB for VMs + 2GB host)
- **Network**: Ability to create private network (192.168.56.0/24)

### Required Software
```bash
# Windows
choco install vagrant virtualbox

# macOS
brew install vagrant virtualbox

# Linux (Ubuntu/Debian)
sudo apt-get install vagrant virtualbox
```

### Verify Installation
```bash
vagrant --version    # v2.2.0+
VBoxManage --version # 6.1+
```

---

## 🚀 Quick Start

### 1. Clone or Download Repository
```bash
cd /path/to/task-manager-deployment
```

### 2. Start Vagrant Cluster
```bash
# Provision VMs and deploy application
vagrant up

# This will:
# - Create 3 Ubuntu VMs
# - Install K3s (master + workers)
# - Deploy application manifests
# - Set up networking and policies
# - Takes 5-10 minutes
```

### 3. Verify Deployment
```bash
# SSH into master node
vagrant ssh master

# Check cluster status
kubectl get nodes
kubectl get all -n task-manager

# View pod status
kubectl get pods -n task-manager -w

# Check services
kubectl get svc -n task-manager
```

### 4. Access Application
```bash
# Update hosts file
# Windows:  C:\Windows\System32\drivers\etc\hosts
# macOS/Linux: /etc/hosts

# Add line:
# 192.168.56.10 task-manager.local

# Access in browser:
# http://task-manager.local    (via Ingress)
# http://192.168.56.10:30080   (via NodePort)
```

### 5. Cleanup
```bash
# Stop and destroy VMs
vagrant destroy -f
```

---

## ⚙️ Configuration

### Environment Variables
File: `ansible/group_vars/all.yml`

```yaml
k3s_version: "v1.27.10+k3s2"        # K3s release version
master_ip: "192.168.56.10"          # Master node IP
app_namespace: "task-manager"       # Kubernetes namespace

# Database credentials (⚠️ Change in production)
db_user: "taskmanager"
db_password: "TaskPass123!"
db_name: "taskmanager"

# Container images
backend_image: "taskmanager-backend:latest"
frontend_image: "taskmanager-frontend:latest"
```

### Kubernetes ConfigMaps
File: `k8s-deployments/configmaps/backend-config.yaml`

```yaml
PORT: "3000"              # Backend server port
NODE_ENV: "production"    # Node environment
DB_HOST: "postgres-service"
DB_PORT: "5432"
DB_NAME: "taskmanager"
```

### Secrets
File: `k8s-deployments/secrets.yaml`

⚠️ **SECURITY WARNING**: Secrets are stored in Git. In production:
- Move to HashiCorp Vault
- Use Kubernetes Sealed Secrets
- Implement RBAC restrictions

---

## 🔧 Kubernetes Resources

### Deployments
- **Backend** (2 replicas): REST API server
- **Frontend** (2 replicas): Web UI
- **PostgreSQL** (1 replica): Data persistence via StatefulSet

### Services
- **backend-service**: ClusterIP on port 3000
- **frontend-service**: NodePort 30080 on port 80
- **postgres-service**: Headless service on port 5432

### ConfigMaps
- **backend-config**: Environment configuration
- **postgres-init**: Database initialization SQL scripts

### Secrets
- **postgres-secrets**: DB credentials (username/password)

### Storage
- **postgres-pvc**: 5Gi PersistentVolume for database

### Auto-Scaling
- **HPA for Backend**: 2-5 replicas, scales on 70% CPU utilization
- **HPA for Frontend**: 2-5 replicas, scales on 70% CPU utilization

### Network Policies
- **frontend-network-policy**: Frontend can reach backend + DNS
- **backend-network-policy**: Backend can reach postgres + DNS
- **postgres-network-policy**: PostgreSQL accepts backend connections
- **default-deny-all**: Explicit deny for all unspecified traffic

### Ingress
- **task-manager-ingress**: Routes `/` to frontend, `/api` to backend
- **Hostname**: task-manager.local
- **Ingress Controller**: Traefik (via K3s default)

---

## 📊 Deployment & Scaling

### Manual Scaling
```bash
# Scale backend to 4 replicas
kubectl scale deployment backend --replicas=4 -n task-manager

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n task-manager
```

### Auto-Scaling Status
```bash
# Check HPA status
kubectl get hpa -n task-manager

# Watch HPA metrics
kubectl describe hpa backend-hpa -n task-manager

# View current CPU usage
kubectl top pods -n task-manager
```

### Monitoring CPU & Memory
```bash
# Requires metrics-server (included in K3s)
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/task-manager/pods
```

---

## 🔐 Network Policies

### Policy Overview
```
Frontend Pod
├─ Ingress: from external traffic (port 80)
├─ Egress: to backend service (port 3000)
└─ Egress: to DNS (port 53 UDP)

Backend Pod
├─ Ingress: from frontend (port 3000)
├─ Egress: to postgres service (port 5432)
└─ Egress: to DNS (port 53 UDP)

PostgreSQL Pod
├─ Ingress: from backend (port 5432)
└─ Egress: to DNS (port 53 UDP)
```

### Testing Network Policies
```bash
# Verify connectivity between pods
kubectl exec -it deployment/frontend -n task-manager -- \
  curl http://backend-service:3000/health

# Test database connection from backend
kubectl exec -it deployment/backend -n task-manager -- \
  psql -h postgres-service -U taskmanager -d taskmanager -c "SELECT 1"
```

---

## 🐛 Troubleshooting

### Pods Not Starting

**Check pod status**:
```bash
kubectl describe pod <pod-name> -n task-manager
kubectl logs <pod-name> -n task-manager
```

**Common Issues**:

1. **ImagePullBackOff**
   - Verify Docker images are available: `docker pull fatmadhouib/taskmanager-backend:v2`
   - Check internet connectivity from nodes

2. **CrashLoopBackOff**
   - Check logs: `kubectl logs -f <pod-name> -n task-manager`
   - Verify environment variables are set correctly

3. **Pending Pods**
   - Check node resources: `kubectl top nodes`
   - Check for PVC issues: `kubectl get pvc -n task-manager`

### Database Connection Issues

```bash
# Check postgres pod is ready
kubectl get pod -l app=postgres -n task-manager

# Verify database initialization
kubectl logs -f statefulset/postgres -n task-manager

# Test connection manually
kubectl exec -it statefulset/postgres -n task-manager -- \
  psql -U taskmanager -d taskmanager -c "\dt"
```

### Network Connectivity Issues

```bash
# Verify network policies aren't blocking traffic
kubectl describe networkpolicy frontend-network-policy -n task-manager

# Test DNS from pod
kubectl exec -it deployment/frontend -n task-manager -- \
  nslookup backend-service

# Test service connectivity
kubectl exec -it deployment/frontend -n task-manager -- \
  curl -v http://backend-service:3000
```

### Ingress Not Working

```bash
# Check ingress status
kubectl describe ingress task-manager-ingress -n task-manager

# Check ingress controller (Traefik) logs
kubectl logs -f deployment/traefik -n kube-system

# Verify service endpoints
kubectl get endpoints -n task-manager
```

### Cluster Issues

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# View cluster events
kubectl get events -n task-manager --sort-by='.lastTimestamp'

# Check K3s on each node
vagrant ssh master    # or worker1, worker2
systemctl status k3s  # master
systemctl status k3s-agent  # workers
```

### Accessing Logs

```bash
# Current pod logs
kubectl logs <pod-name> -n task-manager

# Follow logs in real-time
kubectl logs -f <pod-name> -n task-manager

# Previous logs (if pod restarted)
kubectl logs --previous <pod-name> -n task-manager

# Logs from all backend pods
kubectl logs -f -l app=backend -n task-manager --all-containers
```

---

## 🔄 Vagrant Commands

```bash
# Start/resume VMs
vagrant up [machine-name]

# Stop VMs (without destroying)
vagrant halt [machine-name]

# Suspend VMs (hibernate)
vagrant suspend [machine-name]

# Resume suspended VMs
vagrant resume [machine-name]

# SSH into VM
vagrant ssh [machine-name]
# machine-name: master, worker1, worker2

# Destroy VMs and cleanup
vagrant destroy -f

# Check VM status
vagrant status

# View VM information
vagrant global-status

# Reload VMs (halt + up)
vagrant reload [machine-name]
```

---

## 🛠️ Development

### Modifying Deployments

1. **Update container image**:
   ```bash
   kubectl set image deployment/backend \
     backend=fatmadhouib/taskmanager-backend:v3 \
     -n task-manager
   ```

2. **Update ConfigMap**:
   ```bash
   kubectl edit configmap backend-config -n task-manager
   # Pods must be restarted to pick up changes
   kubectl rollout restart deployment/backend -n task-manager
   ```

3. **Scale replicas**:
   ```bash
   kubectl patch deployment backend -p '{"spec":{"replicas":3}}' -n task-manager
   ```

4. **View deployment history**:
   ```bash
   kubectl rollout history deployment/backend -n task-manager
   ```

### Testing Changes Locally

1. SSH into master node:
   ```bash
   vagrant ssh master
   cd k8s-deployments
   ```

2. Apply changes:
   ```bash
   kubectl apply -f deployments/backend-deployment.yaml
   ```

3. Verify changes:
   ```bash
   kubectl rollout status deployment/backend -n task-manager
   ```

### Port Forwarding for Local Testing

```bash
# Forward backend to localhost:3000
kubectl port-forward svc/backend-service 3000:3000 -n task-manager

# Forward frontend to localhost:8080
kubectl port-forward svc/frontend-service 8080:80 -n task-manager

# In browser: http://localhost:8080
```

---

## 📝 Deployment Review

See [DEPLOYMENT_REVIEW.md](DEPLOYMENT_REVIEW.md) for:
- Security analysis
- Best practices recommendations
- Configuration checklist
- Pre/post-deployment verification steps

---

## 📞 Support & Troubleshooting

### Common Issues & Solutions
- See [Troubleshooting](#troubleshooting) section above
- Check pod logs: `kubectl logs -f <pod-name> -n task-manager`
- Review Kubernetes events: `kubectl describe pod <pod-name> -n task-manager`

### Useful Resources
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)

---

## 📄 License

Specify your license here

## 👥 Contributing

Contributions welcome! Please follow:
1. Create feature branch
2. Make changes and test
3. Submit pull request with description

---

**Last Updated**: May 4, 2026  
**K3s Version**: v1.27.10+k3s2  
**Status**: Production Ready ✅
