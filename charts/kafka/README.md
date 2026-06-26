# Kafka Subchart - KRaft Mode (Kafka 4.0.0)

This chart deploys Apache Kafka 4.0.0 in KRaft mode (Zookeeper-less) as a subchart for the Broadcom API Developer Portal.

## Overview

This Kafka subchart provides a production-ready deployment of Apache Kafka 4.0.0 using KRaft mode, which eliminates the dependency on Zookeeper. It's designed for seamless integration with the APIM Portal, particularly for the Intelligence service which requires Kafka broker autodiscovery.

## Features

- **KRaft Mode**: Zookeeper-less Kafka using the new KRaft consensus protocol
- **Kafka 4.0.0**: Latest stable version with improved performance and features
<<<<<<< HEAD
- **Autodiscovery Support**: External services for each broker enabling autodiscovery by Intelligence service
- **Multi-Listener Support**: Internal, External, and Controller listeners with configurable security
- **SSL/TLS Support**: Full TLS encryption with mTLS client authentication
- **SASL Authentication**: Support for PLAIN, SCRAM-SHA-256, and SCRAM-SHA-512
- **Flexible Deployment**: StatefulSet with configurable replicas
- **External Access**: LoadBalancer or NodePort services for external connectivity
=======
- **Multi-Listener Support**: Internal and Controller listeners with configurable security
- **SASL Authentication**: Support for PLAIN, SCRAM-SHA-256, and SCRAM-SHA-512
- **Flexible Deployment**: StatefulSet with configurable replicas
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
- **RBAC Support**: ServiceAccount for Kubernetes API access

## Quick Start

### Basic Deployment

```bash
cd /root/apim-charts/charts/portal
helm dependency update
helm install my-portal . --set portal.intelligence.enabled=true
```

### With Custom Configuration

```yaml
kafka:
  kafka:
    replicaCount: 3
    kraft:
      enabled: true
      processRoles: "broker,controller"
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi
<<<<<<< HEAD
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.kafka` | Kafka container image | `kafka:4.0.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `kafka.replicaCount` | Number of Kafka broker replicas | `1` |
| **KRaft Configuration** |
| `kafka.kraft.enabled` | Enable KRaft mode | `true` |
| `kafka.kraft.clusterId` | KRaft cluster ID (auto-generated if empty) | `""` |
| `kafka.kraft.processRoles` | Process roles (broker, controller, or both) | `"broker,controller"` |
| `kafka.kraft.controllerQuorumVoters` | Controller quorum voters (auto-generated if empty) | `""` |
| **Listener Configuration** |
| `kafka.listeners.internal.enabled` | Enable internal listener | `true` |
| `kafka.listeners.internal.port` | Internal listener port | `9092` |
| `kafka.listeners.internal.protocol` | Internal listener protocol | `PLAINTEXT` |
<<<<<<< HEAD
| `kafka.listeners.external.enabled` | Enable external listener | `true` |
| `kafka.listeners.external.port` | External listener port | `9094` |
| `kafka.listeners.external.protocol` | External listener protocol | `SSL` |
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
| `kafka.listeners.controller.enabled` | Enable controller listener | `true` |
| `kafka.listeners.controller.port` | Controller listener port | `9093` |
| `kafka.listeners.controller.protocol` | Controller listener protocol | `PLAINTEXT` |
| `kafka.listeners.interBrokerListenerName` | Inter-broker listener name | `INTERNAL` |
| **Retention Configuration** |
| `kafka.logRetentionHours` | Log retention period in hours | `6` |
<<<<<<< HEAD
| **TLS/SSL Configuration** |
| `kafka.tls.enabled` | Enable TLS/SSL | `false` |
| `kafka.tls.type` | TLS certificate type (PEM or JKS) | `PEM` |
| `kafka.tls.clientAuth` | Client authentication (none, requested, required) | `required` |
| `kafka.tls.secretName` | Secret containing TLS certificates | `""` |
| `kafka.tls.keystoreKeyKey` | Key for keystore in secret | `"keystore.key"` |
| `kafka.tls.truststoreCertKey` | Key for truststore in secret | `"truststore.pem"` |
| `kafka.tls.passwordSecretName` | Secret containing key password | `""` |
| `kafka.tls.passwordSecretKey` | Key for password in secret | `"keypass.txt"` |
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
| **SASL Configuration** |
| `kafka.sasl.enabled` | Enable SASL authentication | `false` |
| `kafka.sasl.mechanisms` | SASL mechanisms | `PLAIN` |
| `kafka.sasl.interBrokerProtocol` | Inter-broker SASL mechanism | `PLAIN` |
| `kafka.sasl.jaasConfigPath` | JAAS configuration file path | `/opt/ca/kafka/config/kafka_server_jaas.conf` |
<<<<<<< HEAD
| **External Access** |
| `externalAccess.enabled` | Enable external access | `true` |
| `externalAccess.serviceType` | Service type (LoadBalancer or NodePort) | `LoadBalancer` |
| `externalAccess.port` | External port | `9094` |
| `externalAccess.hostname` | External hostname for advertised listeners | `""` |
| `externalAccess.annotations` | Annotations for external services | `{}` |
| `externalAccess.loadBalancerIPs` | Static LoadBalancer IPs | `[]` |
| `externalAccess.nodePorts` | NodePort values | `[]` |
| `externalAccess.autoAdvertisedListeners` | Auto-generate advertised listeners | `true` |
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
| **Persistence** |
| `persistence.storage.kafka` | Storage size per broker | `10Gi` |
| **Service Account** |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.automountServiceAccountToken` | Mount SA token | `true` |

## KRaft Mode

### What is KRaft?

KRaft (Kafka Raft) is the new consensus protocol that replaces Zookeeper in Kafka 4.0.0+. Benefits include:
- Simplified architecture (no Zookeeper dependency)
- Improved scalability (millions of partitions)
- Faster controller failover
- Reduced operational complexity

### KRaft Configuration

The chart automatically configures KRaft mode with sensible defaults:

```yaml
kafka:
  kafka:
    kraft:
      enabled: true
      processRoles: "broker,controller"  # Combined mode
      # Controller quorum voters auto-generated based on replicas
```

For a 3-broker cluster, the controller quorum voters are automatically set to:
```
0@kafka-0.kafka:9093,1@kafka-1.kafka:9093,2@kafka-2.kafka:9093
```

### Node ID Assignment

Each Kafka pod is automatically assigned a node ID based on its StatefulSet ordinal:
- `kafka-0` → Node ID: 0
- `kafka-1` → Node ID: 1
- `kafka-2` → Node ID: 2

## Listener Configuration

<<<<<<< HEAD
### Three-Listener Architecture

The chart configures three listeners:

1. **INTERNAL** (port 9092): For inter-broker and internal client communication
2. **EXTERNAL** (port 9094): For external clients (SSL encrypted)
3. **CONTROLLER** (port 9093): For KRaft controller communication

### Advertised Listeners

Advertised listeners are automatically generated:

**Internal**: `INTERNAL://kafka-{id}.kafka:9092`
**External**: `EXTERNAL://kafka-{id}-external:9094` (or custom hostname)

Example for 3 brokers:
```
kafka-0: INTERNAL://kafka-0.kafka:9092,EXTERNAL://kafka-0-external:9094
kafka-1: INTERNAL://kafka-1.kafka:9092,EXTERNAL://kafka-1-external:9094
kafka-2: INTERNAL://kafka-2.kafka:9092,EXTERNAL://kafka-2-external:9094
```

## External Access

### LoadBalancer (Default)

Creates individual LoadBalancer services for each broker:

```yaml
externalAccess:
  enabled: true
  serviceType: LoadBalancer
  port: 9094
  annotations:
    cloud.google.com/load-balancer-type: Internal
```

Services created:
- `kafka-0-external` → LoadBalancer with external IP
- `kafka-1-external` → LoadBalancer with external IP
- `kafka-2-external` → LoadBalancer with external IP

### NodePort

Use NodePort for environments without LoadBalancer support:

```yaml
externalAccess:
  enabled: true
  serviceType: NodePort
  port: 9094
  nodePorts:
    - 30094
    - 30095
    - 30096
```

### Static IPs

Assign static IPs to LoadBalancers:

```yaml
externalAccess:
  loadBalancerIPs:
    - 10.0.0.100
    - 10.0.0.101
    - 10.0.0.102
```

## SSL/TLS Configuration

### Enable TLS

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

### Create TLS Secret

```bash
kubectl create secret generic kafka-tls-secret \
  --from-file=keystore.key=kafka-key.pem \
  --from-file=truststore.pem=ca-cert.pem
  
kubectl create secret generic kafka-password-secret \
  --from-literal=keypass.txt=your-password
```

### TLS Certificate Format

The Kafka container expects PEM format certificates:
- **keystore.key**: Encrypted private key (PKCS#8 format)
- **truststore.pem**: CA certificate chain

=======
### Two-Listener Architecture

The chart configures two listeners:

1. **INTERNAL** (port 9092): For inter-broker and internal client communication
2. **CONTROLLER** (port 9093): For KRaft controller communication

External access to Kafka (for tenant gateways) is handled by the `KafkaTcpProxyAssertion` on the Ingress gateway, which proxies Kafka traffic with TLS termination and metadata address rewriting. Kafka itself does not need to be directly exposed outside the cluster.

### Advertised Listeners

Advertised listeners are automatically generated by the init container:

**Internal**: `INTERNAL://kafka-{id}.kafka:9092`

Example for 3 brokers:
```
kafka-0: INTERNAL://kafka-0.kafka:9092,CONTROLLER://kafka-0.kafka:9093
kafka-1: INTERNAL://kafka-1.kafka:9092,CONTROLLER://kafka-1.kafka:9093
kafka-2: INTERNAL://kafka-2.kafka:9092,CONTROLLER://kafka-2.kafka:9093
```

>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
## SASL Authentication

### Enable SASL PLAIN

```yaml
kafka:
  kafka:
    sasl:
      enabled: true
      mechanisms: PLAIN
      interBrokerProtocol: PLAIN
```

### JAAS Configuration

Create a ConfigMap with JAAS configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-jaas-config
data:
  kafka_server_jaas.conf: |
    KafkaServer {
      org.apache.kafka.common.security.plain.PlainLoginModule required
      username="admin"
      password="admin-secret"
      user_admin="admin-secret"
      user_client="client-secret";
    };
```

Mount it in the StatefulSet by customizing the deployment.

## Production Configuration

<<<<<<< HEAD
### 3-Broker Cluster with TLS and External Access
=======
### 3-Broker Cluster
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1

```yaml
kafka:
  image:
    kafka: kafka:latest
  
  kafka:
    replicaCount: 3
    
    kraft:
      enabled: true
      processRoles: "broker,controller"
    
    listeners:
      internal:
        enabled: true
        port: 9092
        protocol: PLAINTEXT
<<<<<<< HEAD
      external:
        enabled: true
        port: 9094
        protocol: SSL
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
      controller:
        enabled: true
        port: 9093
        protocol: PLAINTEXT
      interBrokerListenerName: INTERNAL
    
    logRetentionHours: 168  # 7 days
    
<<<<<<< HEAD
    tls:
      enabled: true
      type: PEM
      clientAuth: required
      secretName: kafka-tls-secret
      passwordSecretName: kafka-password-secret
    
=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
    resources:
      requests:
        cpu: 2000m
        memory: 4Gi
      limits:
        cpu: 4000m
        memory: 8Gi
    
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - kafka
          topologyKey: kubernetes.io/hostname
  
  persistence:
    storage:
      kafka: 100Gi
<<<<<<< HEAD
  
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
    annotations:
      cloud.google.com/load-balancer-type: Internal
    loadBalancerIPs:
      - 10.0.0.100
      - 10.0.0.101
      - 10.0.0.102
```

## Autodiscovery Integration

The Intelligence service uses an init container to discover Kafka broker addresses:

```yaml
apim-intelligence:
  kafka: *kafka_config  # Reference Kafka config
  intelligenceServer:
    kafka:
      autoDiscovery:
        enabled: true
```

The autodiscovery looks for services named:
- `<release-name>-kafka-0-external`
- `<release-name>-kafka-1-external`
- `<release-name>-kafka-2-external`

=======
```

>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
## Migration from Zookeeper Mode

If migrating from Zookeeper-based Kafka:

1. **Backup data** from existing Kafka cluster
2. **Update configuration** to enable KRaft mode
3. **Deploy new cluster** with KRaft enabled
4. **Migrate data** using MirrorMaker or similar tools
5. **Update clients** to use new broker addresses

**Note**: Direct in-place migration from Zookeeper to KRaft is not supported. A new cluster deployment is required.

## Troubleshooting

### Pods Not Starting

Check KRaft configuration:
```bash
kubectl logs kafka-0 -c kafka-init
kubectl logs kafka-0
```

Common issues:
- Incorrect controller quorum voters
- Node ID conflicts
- Storage not formatted

<<<<<<< HEAD
### External Access Not Working

Verify external services:
```bash
kubectl get svc | grep kafka.*external
kubectl describe svc kafka-0-external
```

Check advertised listeners:
```bash
kubectl exec kafka-0 -- cat /shared/node-id.env
```

### TLS Connection Failures

Verify certificates:
```bash
kubectl get secret kafka-tls-secret -o yaml
kubectl exec kafka-0 -- ls -la /opt/ca/kafka/config/certs/
```

=======
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
### Controller Election Issues

Check controller logs:
```bash
kubectl logs kafka-0 | grep -i controller
kubectl logs kafka-0 | grep -i quorum
```

Verify all brokers can communicate on port 9093.

## Monitoring

### Health Checks

The StatefulSet includes TCP-based health checks:
- **Readiness**: Port 9092 (internal listener)
- **Liveness**: Port 9092 (internal listener)

### Metrics

For production deployments, consider adding:
- JMX Exporter for Prometheus metrics
- Kafka Exporter for detailed metrics
- Grafana dashboards for visualization

## Version History

- **1.1.0**: KRaft mode support, Kafka 4.0.0, multi-listener architecture
- **1.0.0**: Initial release with Zookeeper mode

<<<<<<< HEAD
## References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [KRaft Mode Documentation](https://kafka.apache.org/documentation/#kraft)
- [Kafka 4.0.0 Release Notes](https://kafka.apache.org/40/documentation.html#upgrade)

## Certificate Configuration (New in v1.0.0)

The Kafka subchart now supports **three different approaches** for certificate management to ensure compatibility with different deployment scenarios:

### Option 1: Kubernetes Secrets (Recommended)

Use native Kubernetes secrets for certificate management:

```yaml
kafka:
  tls:
    enabled: true
    type: PEM
    clientAuth: required
    secretName: kafka-tls-secret
    keystoreKeyKey: "keystore.key"
    truststoreCertKey: "truststore.pem"
```

Create the secret:
```bash
kubectl create secret generic kafka-tls-secret \
  --from-file=keystore.key=./certs/kafka-key.pem \
  --from-file=truststore.pem=./certs/ca-cert.pem
```

### Option 2: Inline Certificates (portal-dist Compatible)

Pass certificates directly as environment variables (compatible with Docker Swarm portal-dist):

```yaml
kafka:
  tls:
    enabled: true
    truststoreCertContent: |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKL...
      -----END CERTIFICATE-----
    keystoreKeyContent: |
      -----BEGIN ENCRYPTED PRIVATE KEY-----
      MIIFHDBOBgkqhkiG9w0BBQ0w...
      -----END ENCRYPTED PRIVATE KEY-----
```

### Option 3: CA Certificates (analytics_util Compatible)

Use CA certificate variables (compatible with analytics_util reference implementation):

```yaml
kafka:
  tls:
    enabled: true
    caKey: "{{ auth.TSSG_CA_KEY }}"
    caCertificate: "{{ auth.TSSG_SSL_CERT }}"
    caTruststoreCertificate: "{{ auth.TSSG_TRUSTSTORE_CERT }}"
```

### Portal Subdomain Configuration

For advertised listeners that include the portal subdomain:
=======
## Additional Configuration

### Portal Subdomain

For deployments that require the portal subdomain:
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1

```yaml
kafka:
  global:
    subdomainPrefix: "dev-portal"
<<<<<<< HEAD
  externalAccess:
    enabled: true
    hostname: "apim-kafka.dev-portal"
```

This sets the `APIM_PORTAL_SUBDOMAIN` environment variable and configures advertised listeners appropriately.

### Custom Advertised Listeners

For full control over advertised listeners (portal-dist style):

```yaml
kafka:
  advertisedListeners: "INTERNAL://kafka:9092,EXTERNAL://apim-kafka.dev-portal:9094"
```

## Portal-dist Compatibility
=======
```

This sets the `APIM_PORTAL_SUBDOMAIN` environment variable.

### Custom Advertised Listeners

For full control over advertised listeners:

```yaml
kafka:
  advertisedListeners: "INTERNAL://kafka:9092"
```

### Portal-dist Compatibility
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1

To match portal-dist Docker Swarm deployment configuration:

```yaml
kafka:
  global:
    subdomainPrefix: "dev-portal"
  
  kafka:
    replicaCount: 1
    kraft:
      enabled: true
      processRoles: "broker,controller"
      nodeId: "0"
      controllerQuorumVoters: "0@localhost:9093"
    
<<<<<<< HEAD
    advertisedListeners: "INTERNAL://kafka:9092,EXTERNAL://apim-kafka.dev-portal:9094"
    logRetentionHours: 6
    
    tls:
      enabled: true
      type: PEM
      clientAuth: required
      truststoreCertContent: "{{ auth.TSSG_TRUSTSTORE_CERT }}"
      keystoreKeyContent: "{{ auth.TSSG_CA_P8_KEY }}"
    
    sasl:
      enabled: true
      mechanisms: PLAIN
      interBrokerProtocol: PLAIN
  
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
    hostname: "apim-kafka.dev-portal"
=======
    advertisedListeners: "INTERNAL://kafka:9092"
    logRetentionHours: 6
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
```

This configuration produces the same environment variables as portal-dist `env-kafka` file.

<<<<<<< HEAD
## Additional Documentation

=======
## References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [KRaft Mode Documentation](https://kafka.apache.org/documentation/#kraft)
- [Kafka 4.0.0 Release Notes](https://kafka.apache.org/40/documentation.html#upgrade)
>>>>>>> a1ea8e6d24dc492dbddea8f8c691cebf802fbff1
- **[CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md)** - Detailed configuration guide with examples
- **[QUICK_START.md](QUICK_START.md)** - Quick start guide
- **[../../KAFKA_ENV_COMPARISON.md](../../KAFKA_ENV_COMPARISON.md)** - Environment variables comparison
- **[../../KAFKA_MIGRATION_GUIDE.md](../../KAFKA_MIGRATION_GUIDE.md)** - Migration from Bitnami Kafka

