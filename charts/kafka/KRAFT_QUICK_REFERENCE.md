# Kafka 4.0.0 KRaft Mode - Quick Reference

## Quick Deploy

```bash
cd /root/apim-charts/charts/portal
helm dependency update
helm install my-portal . --set portal.intelligence.enabled=true
```

## Key Ports

| Port | Listener | Protocol | Purpose |
|------|----------|----------|---------|
| 9092 | INTERNAL | PLAINTEXT | Internal clients |
| 9094 | EXTERNAL | SSL | External clients |
| 9093 | CONTROLLER | PLAINTEXT | KRaft controllers |

## Default Configuration

```yaml
kafka:
  kafka:
    replicaCount: 1
    kraft:
      enabled: true  # KRaft mode ON
      processRoles: "broker,controller"
    logRetentionHours: 6
  externalAccess:
    enabled: true  # External access ON
    serviceType: LoadBalancer
    port: 9094
```

## Common Commands

### Check Pods
```bash
kubectl get pods -l app=kafka
```

### Check Logs
```bash
kubectl logs kafka-0
kubectl logs kafka-0 -c kafka-init  # Init container
```

### Check Services
```bash
kubectl get svc -l app=kafka
```

### Check Configuration
```bash
kubectl get cm kafka-config -o yaml
kubectl exec kafka-0 -- cat /shared/node-id.env
```

### Test Connectivity
```bash
# Internal
kubectl run test --rm -it --image=busybox -- nc -zv kafka 9092

# External
EXTERNAL_IP=$(kubectl get svc kafka-0-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
nc -zv $EXTERNAL_IP 9094
```

### Create Topic
```bash
kubectl exec kafka-0 -- /opt/ca/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic test --partitions 3 --replication-factor 1
```

### List Topics
```bash
kubectl exec kafka-0 -- /opt/ca/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list
```

### Produce Messages
```bash
kubectl exec -it kafka-0 -- /opt/ca/kafka/bin/kafka-console-producer.sh \
  --broker-list localhost:9092 --topic test
```

### Consume Messages
```bash
kubectl exec -it kafka-0 -- /opt/ca/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic test --from-beginning
```

## Environment Variables (KRaft)

```bash
# Core KRaft
KAFKA_CFG_NODE_ID=0
KAFKA_CFG_PROCESS_ROLES=broker,controller
KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka-0.kafka:9093
KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER

# Listeners
KAFKA_CFG_LISTENERS=INTERNAL://0.0.0.0:9092,EXTERNAL://0.0.0.0:9094,CONTROLLER://0.0.0.0:9093
KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka-0.kafka:9092,EXTERNAL://kafka-0-external:9094
KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:SSL,CONTROLLER:PLAINTEXT
KAFKA_CFG_INTER_BROKER_LISTENER_NAME=INTERNAL

# Retention
KAFKA_CFG_LOG_RETENTION_HOURS=6
```

## Enable TLS

```yaml
kafka:
  kafka:
    tls:
      enabled: true
      type: PEM
      clientAuth: required
      secretName: kafka-tls-secret
      passwordSecretName: kafka-password-secret
```

Create secret:
```bash
kubectl create secret generic kafka-tls-secret \
  --from-file=keystore.key=kafka-key.pem \
  --from-file=truststore.pem=ca-cert.pem

kubectl create secret generic kafka-password-secret \
  --from-literal=keypass.txt=your-password
```

## Enable SASL

```yaml
kafka:
  kafka:
    sasl:
      enabled: true
      mechanisms: PLAIN
      interBrokerProtocol: PLAIN
```

## Production Config (3 Brokers)

```yaml
kafka:
  kafka:
    replicaCount: 3
    kraft:
      enabled: true
    logRetentionHours: 168
    resources:
      requests:
        cpu: 2000m
        memory: 4Gi
      limits:
        cpu: 4000m
        memory: 8Gi
  persistence:
    storage:
      kafka: 100Gi
  externalAccess:
    enabled: true
    loadBalancerIPs:
      - 10.0.0.100
      - 10.0.0.101
      - 10.0.0.102
```

## Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod kafka-0
kubectl logs kafka-0 -c kafka-init
kubectl logs kafka-0
```

### Controller Issues
```bash
kubectl logs kafka-0 | grep -i "controller\|quorum"
```

### External Access Issues
```bash
kubectl get svc | grep external
kubectl describe svc kafka-0-external
kubectl exec kafka-0 -- cat /shared/node-id.env
```

### TLS Issues
```bash
kubectl get secret kafka-tls-secret
kubectl exec kafka-0 -- ls -la /opt/ca/kafka/config/certs/
kubectl exec kafka-0 -- grep "ssl\." /opt/ca/kafka/config/server.properties
```

## Key Differences from Zookeeper Mode

| Aspect | Zookeeper | KRaft |
|--------|-----------|-------|
| Dependency | Requires Zookeeper | Standalone |
| Ports | 1 (9092) | 3 (9092, 9093, 9094) |
| Node ID | Auto-assigned | Explicit |
| Controller | Separate | Integrated |
| Quorum | Zookeeper | Raft |
| Startup | Slower | Faster |

## Verification Checklist

- [ ] Pods running: `kubectl get pods -l app=kafka`
- [ ] KRaft mode: `kubectl logs kafka-0 | grep -i kraft`
- [ ] Controller elected: `kubectl logs kafka-0 | grep -i controller`
- [ ] External services: `kubectl get svc | grep external`
- [ ] LoadBalancer IPs: `kubectl get svc kafka-0-external`
- [ ] Autodiscovery: `kubectl logs <intelligence-pod> -c kafka-broker-discovery`
- [ ] Topics work: Create and list topics
- [ ] Producer works: Send messages
- [ ] Consumer works: Receive messages

## Documentation

- **Full README**: `charts/kafka/README.md`
- **Upgrade Guide**: `KAFKA_4.0_KRAFT_UPGRADE_GUIDE.md`
- **Env Comparison**: `KAFKA_ENV_COMPARISON.md`
- **Implementation**: `KAFKA_4.0_KRAFT_IMPLEMENTATION_SUMMARY.md`

## Support

Check logs in this order:
1. `kubectl logs kafka-0 -c kafka-init` (Init container)
2. `kubectl logs kafka-0` (Main container)
3. `kubectl get cm kafka-config -o yaml` (Configuration)
4. `kubectl exec kafka-0 -- cat /shared/node-id.env` (Node config)
5. `kubectl get svc | grep kafka` (Services)

