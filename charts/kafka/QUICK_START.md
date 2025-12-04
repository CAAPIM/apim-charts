# Kafka Subchart - Quick Start Guide

## Basic Usage

### 1. Deploy with Portal Chart

The Kafka subchart is automatically deployed when Intelligence is enabled:

```bash
cd /root/apim-charts/charts/portal

# Update dependencies
helm dependency update

# Install with Intelligence enabled
helm install my-portal . \
  --set portal.intelligence.enabled=true
```

### 2. Minimal Configuration

Default configuration (in portal `values.yaml`):

```yaml
kafka:
  kafka:
    replicaCount: 1
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
```

### 3. Verify Deployment

```bash
# Check Kafka pods
kubectl get pods -l app=kafka

# Check Kafka services
kubectl get svc -l app=kafka

# Check Kafka logs
kubectl logs kafka-0
```

## Common Configurations

### Production Setup (3 Brokers)

```yaml
kafka:
  kafka:
    replicaCount: 3
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi
  persistence:
    storage:
      kafka: 50Gi
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    annotations:
      cloud.google.com/load-balancer-type: Internal
```

### NodePort Configuration

```yaml
kafka:
  externalAccess:
    enabled: true
    serviceType: NodePort
    port: 9094
    nodePorts:
      - 30094
      - 30095
      - 30096
```

### Static LoadBalancer IPs

```yaml
kafka:
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    loadBalancerIPs:
      - 10.0.0.100
      - 10.0.0.101
      - 10.0.0.102
```

### Development Setup (No External Access)

```yaml
kafka:
  kafka:
    replicaCount: 1
  externalAccess:
    enabled: false
```

**Note**: Disabling external access will break Intelligence service autodiscovery.

## Autodiscovery Configuration

### Enable Autodiscovery in Intelligence

```yaml
apim-intelligence:
  kafka: *kafka_config  # Reference Kafka config
  intelligenceServer:
    kafka:
      autoDiscovery:
        enabled: true
```

### Disable Autodiscovery (Manual Broker List)

```yaml
apim-intelligence:
  intelligenceServer:
    kafka:
      autoDiscovery:
        enabled: false
      externalAdvertisedBrokers: "10.0.0.100:9094,10.0.0.101:9094"
```

## Troubleshooting

### Kafka Pod Not Starting

```bash
# Check pod status
kubectl describe pod kafka-0

# Check logs
kubectl logs kafka-0

# Common issues:
# - Zookeeper not ready
# - Storage class not available
# - Resource constraints
```

### External Service No IP

```bash
# Check service
kubectl get svc kafka-0-external

# If pending:
# - Check LoadBalancer provisioner
# - Check cloud provider quotas
# - Try NodePort instead
```

### Autodiscovery Failing

```bash
# Check Intelligence init container
kubectl logs <intelligence-pod> -c kafka-broker-discovery

# Common issues:
# - RBAC not enabled
# - External services not created
# - Services not ready
```

### Connection Refused

```bash
# Test internal connectivity
kubectl run test --rm -it --image=busybox -- nc -zv kafka 9092

# Test external connectivity
kubectl get svc kafka-0-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
nc -zv <ip> 9094

# Common issues:
# - Kafka not ready
# - Zookeeper connection failed
# - Network policies blocking traffic
```

## Useful Commands

### Check Kafka Status

```bash
# Pods
kubectl get pods -l app=kafka

# Services
kubectl get svc -l app=kafka

# PVCs
kubectl get pvc -l app=kafka

# ConfigMap
kubectl get cm -o yaml | grep -A 20 kafka-config
```

### Scale Kafka

```bash
# Update values.yaml
kafka:
  kafka:
    replicaCount: 3

# Upgrade release
helm upgrade my-portal ./portal
```

### View Kafka Configuration

```bash
kubectl get cm <release>-kafka-config -o yaml
```

### Access Kafka Shell

```bash
kubectl exec -it kafka-0 -- /bin/bash

# Inside pod
cd /opt/ca/kafka
./bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

## Integration Examples

### Connect from Application

**Internal (from within cluster):**
```
kafka:9092
```

**External (from outside cluster):**
```bash
# Get external IP
kubectl get svc kafka-0-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Connect
<external-ip>:9094
```

### Producer Example

```bash
kubectl exec -it kafka-0 -- /opt/ca/kafka/bin/kafka-console-producer.sh \
  --broker-list localhost:9092 \
  --topic test-topic
```

### Consumer Example

```bash
kubectl exec -it kafka-0 -- /opt/ca/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

## Next Steps

- Review full documentation: [README.md](README.md)
- Check migration guide: [KAFKA_MIGRATION_GUIDE.md](../../KAFKA_MIGRATION_GUIDE.md)
- Review implementation details: [KAFKA_SUBCHART_IMPLEMENTATION.md](../../KAFKA_SUBCHART_IMPLEMENTATION.md)

## Support

For issues:
1. Check Kafka logs: `kubectl logs kafka-0`
2. Check Zookeeper: `kubectl logs zookeeper-0`
3. Check Intelligence autodiscovery: `kubectl logs <intelligence-pod> -c kafka-broker-discovery`
4. Review configuration: `kubectl get cm <release>-kafka-config -o yaml`

