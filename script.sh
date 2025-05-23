#!/bin/bash

set -e

# Trap to clean up background monitor on script exit
cleanup() {
    echo "Cleaning up..."
    if [[ -n "$MONITOR_PID" ]]; then
        kill "$MONITOR_PID" 2>/dev/null || true
        wait "$MONITOR_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

LOAD_BALANCER_URL=$(kubectl get service autoscaling-springboot-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LOAD_BALANCER_URL" ]; then
    echo "LoadBalancer URL not found. Checking service status..."
    kubectl get svc autoscaling-springboot-service
    exit 1
fi

echo "LoadBalancer URL: http://$LOAD_BALANCER_URL"
echo "Starting load test..."

echo "Testing basic connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$LOAD_BALANCER_URL/")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Service not responding as expected (HTTP $HTTP_CODE)"
    exit 1
fi


generate_load() {
    local duration=$1
    local concurrent_requests=$2

    echo "Generating load for $duration seconds with $concurrent_requests concurrent requests..."

    for i in $(seq 1 $concurrent_requests); do
        (
            end_time=$(($(date +%s) + duration))
            while [ $(date +%s) -lt $end_time ]; do
                curl -s "http://$LOAD_BALANCER_URL/load" > /dev/null &
                sleep 0.1
            done
            wait
        ) &
    done
    wait
}


monitor_scaling() {
    echo "Monitoring pod scaling..."
    while true; do
        echo "$(date): Pods: $(kubectl get pods -l app=autoscaling-springboot --no-headers | wc -l), HPA Status:"
        kubectl get hpa autoscaling-springboot-hpa --no-headers
        sleep 10
    done
}

monitor_scaling &
MONITOR_PID=$!
echo "Monitoring process started with PID $MONITOR_PID"

echo "Phase 1: Light load (30 seconds, 2 concurrent requests)"
generate_load 30 2
sleep 30

echo "Phase 2: Medium load (60 seconds, 5 concurrent requests)"
generate_load 60 5
sleep 60

echo "Phase 3: Heavy load (90 seconds, 10 concurrent requests)"
generate_load 90 10
sleep 120

echo "Phase 4: Stopping load to test scale-down"
sleep 300

echo "Load test completed!"
echo "Final status:"
kubectl get pods -l app=autoscaling-springboot
kubectl get hpa autoscaling-springboot-hpa
