# EKS Autoscaling Demo with Spring Boot

This project demonstrates horizontal pod autoscaling (HPA) on Amazon EKS using a Spring Boot application that can generate CPU load on demand.

## 🏗️ Architecture

- **Spring Boot Application**: Simple REST API with load generation endpoint
- **Amazon EKS**: Kubernetes cluster for container orchestration
- **Horizontal Pod Autoscaler**: Automatically scales pods based on CPU utilization
- **Application Load Balancer**: Distributes traffic across pods

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- `kubectl` installed
- `eksctl` installed
- Docker (for building images)

## 🚀 Quick Start

### 1. Clone and Build

```bash
git clone <your-repo-url>
cd autoscaling-springboot-eks

# Build the application (assuming Maven is installed)
mvn clean package

# Build Docker image
docker build -t autoscaling-springboot-eks .
docker tag autoscaling-springboot-eks:latest aasawarimongodb/autoscaling-springboot-eks:latest
docker push aasawarimongodb/autoscaling-springboot-eks:latest
```

### 2. Create EKS Cluster

```bash
eksctl create cluster \
  --name autoscaling-cluster \
  --region us-east-1 \
  --nodegroup-name app-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

### 3. Deploy Application

```bash
# Connect to cluster
aws eks update-kubeconfig --region us-east-1 --name autoscaling-cluster

# Install metrics server (required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Deploy application
kubectl apply -f deployment.yaml

# Create HPA
kubectl apply -f hpa.yaml

# Wait for deployment
kubectl get pods -w
```

## 🧪 Testing Autoscaling

### Automated Testing Script

Use the provided automation script for comprehensive testing:

```bash
# Make script executable
chmod +x script.sh

# Run automated test
./script.sh
```

### Manual Testing

**Monitor scaling in real-time:**
```bash
# Terminal 1 - Monitor HPA
watch -n 5 'kubectl get hpa'

# Terminal 2 - Monitor Pods  
watch -n 5 'kubectl get pods -l app=autoscaling-springboot'

# Terminal 3 - Monitor Resource Usage
watch -n 10 'kubectl top pods'
```

**Generate load:**
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get service autoscaling-springboot-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$LB_URL/                    # Basic health check
curl http://$LB_URL/load               # Generate 10-second CPU load

# Generate sustained load (run multiple times)
for i in {1..10}; do
  curl http://$LB_URL/load &
done
```

## 📊 Expected Behavior

| Phase | Time | CPU Usage | Pods | Description |
|-------|------|-----------|------|-------------|
| Initial | 0s | ~5% | 1 | Application starts with 1 pod |
| Load Start | 0-30s | >50% | 1 | CPU usage increases above threshold |
| Scale Up | 30-120s | 50-80% | 2-4 | HPA creates additional pods |
| Stable | 2-5min | 40-60% | 3-4 | Load distributed, CPU stabilizes |
| Load Stop | 5min+ | <10% | 3-4 | Load generation stops |
| Scale Down | 10-15min | <10% | 1 | Pods terminate after cooldown |

## 🔧 Configuration

### Application Endpoints

- `GET /` - Health check endpoint
- `GET /load` - Generates CPU load for 10 seconds

### HPA Configuration

```yaml
minReplicas: 1
maxReplicas: 5
targetCPUUtilizationPercentage: 50
```

### Resource Limits

```yaml
requests:
  cpu: "200m"
  memory: "256Mi"
limits:
  cpu: "500m" 
  memory: "512Mi"
```

## 🐛 Troubleshooting

### Pods Stuck in Pending State

```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Scale node group if needed
eksctl scale nodegroup --cluster=autoscaling-cluster --nodes=3 --name=app-nodes --region=us-east-1
```

### HPA Shows Unknown CPU

```bash
# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Verify resource requests are set
kubectl describe deployment autoscaling-springboot | grep -A 5 Requests
```

### LoadBalancer External IP Pending

```bash
# Check service status
kubectl describe svc autoscaling-springboot-service

# Alternative: Use port-forward
kubectl port-forward svc/autoscaling-springboot-service 8080:80
# Then use http://localhost:8080
```

## 📁 Project Structure

```
autoscaling-springboot-eks/
├── src/main/java/com/demo/autoscaling_springboot_eks/
│   ├── AutoscalingSpringbootEksApplication.java
│   └── Controller/
│       └── EKSController.java
├── Dockerfile
├── deployment.yaml          # Kubernetes deployment
├── hpa.yaml                # Horizontal Pod Autoscaler
├── test-autoscaling.sh     # Automation script
└── README.md
```

## 🧹 Cleanup

```bash
# Delete application resources
kubectl delete -f deployment.yaml
kubectl delete -f hpa.yaml

# Delete EKS cluster
eksctl delete cluster --name autoscaling-cluster --region ap-south-1
```

## 📝 Notes

- **Scale-up**: Triggered when CPU > 50% for ~30 seconds
- **Scale-down**: Triggered after CPU < 50% for ~5 minutes (prevents flapping)
- **Load Generation**: `/load` endpoint creates CPU-intensive mathematical calculations
- **Monitoring**: Use `kubectl top pods` and `kubectl get hpa -w` for real-time monitoring

## 🚨 Cost Warning

Remember to delete your EKS cluster after testing to avoid AWS charges:
```bash
eksctl delete cluster --name autoscaling-cluster --region ap-south-1
```

---

**Happy Scaling! 🎯**