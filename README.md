# EKS Autoscaling Demo with Spring Boot

This project demonstrates horizontal pod autoscaling (HPA) on Amazon EKS using a Spring Boot application that generates CPU load on demand.

## 🏗️ Architecture

- **Spring Boot Application**: REST API with endpoints for health check and CPU load
- **Amazon EKS**: Kubernetes cluster hosting the application
- **Horizontal Pod Autoscaler (HPA)**: Automatically scales pods based on CPU usage
- **Application Load Balancer**: Distributes incoming traffic to pods
- **Bash Script**: Simulates load to test autoscaling

---

## 📋 Prerequisites

Ensure the following tools are installed and configured:

- AWS CLI (configured with appropriate IAM credentials)
- `kubectl`
- `eksctl`
- Docker (with access to push to Docker Hub)
- Maven (to build the Spring Boot app)

---

## 🚀 Quick Start

### 1. Clone and Build

```bash
git clone <your-repo-url>
cd autoscaling-springboot-eks

# Build the application
mvn clean package

# Build and push the Docker image for amd64
docker buildx create --use
docker buildx build --platform linux/amd64 -t aasawarimongodb/autoscaling-springboot-eks:latest --push .
````

---

### 2. Create the EKS Cluster

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

---

### 3. Deploy the App to EKS

```bash
# Connect to the new cluster
aws eks update-kubeconfig --region us-east-1 --name autoscaling-cluster

# Install metrics server (required by HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Deploy the Spring Boot app and HPA
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml

# Ensure only 1 pod is running initially
kubectl scale deployment autoscaling-springboot --replicas=1

# Check pod and HPA status
kubectl get pods
kubectl get hpa
```

---

## 🧪 Test Autoscaling Behavior

### Option 1: Automated Script

Use the provided script to simulate load in phases.

```bash
# Make the script executable
chmod +x script.sh

# Run the load test script
./script.sh
```

The script will:

* Check connectivity
* Simulate increasing CPU load in 3 phases (light → medium → heavy)
* Monitor pod scaling live
* Wait and confirm scale-down after 5 minutes

### Option 2: Manual Load Test

```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get service autoscaling-springboot-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Generate repeated load
for i in {1..20}; do
  curl http://$LB_URL/load &
done
```

---

## 📊 Expected Autoscaling Behavior

| Phase      | Time     | CPU Usage  | Pods | Description                   |
| ---------- | -------- | ---------- | ---- | ----------------------------- |
| Initial    | 0–10s    | Low (<10%) | 1    | Starts with one pod           |
| Load Phase | 30–120s  | >50%       | 2–5  | HPA scales up                 |
| Peak Load  | \~3 mins | \~70–90%   | \~5  | Max pods running              |
| Idle Phase | 5–10 min | <20%       | 1    | HPA scales down automatically |


## 🧹 Cleanup

To avoid AWS charges:

```bash
kubectl delete all --all
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
eksctl delete cluster --name autoscaling-cluster --region us-east-1
```

---

## 🚨 Cost Note

EKS incurs charges even when idle. Remember to delete the cluster when finished.

