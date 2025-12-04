# Kafka Subchart Configuration Guide

## Overview

This guide explains how to configure the Kafka subchart to match different deployment scenarios, including portal-dist compatibility and production security settings.

---

## Certificate Configuration

The Kafka subchart supports **three different approaches** for certificate management:

### Option 1: Kubernetes Secrets (Recommended for Kubernetes)

**Best for**: Native Kubernetes deployments with proper secret management.

```yaml
kafka:
  tls:
    enabled: true
    type: PEM
    clientAuth: required
    secretName: kafka-tls-secret
    keystoreKeyKey: "keystore.key"
    truststoreCertKey: "truststore.pem"
    passwordSecretName: kafka-password-secret
    passwordSecretKey: "keypass.txt"
```

**Create the secret:**
```bash
kubectl create secret generic kafka-tls-secret \
  --from-file=keystore.key=./certs/kafka-key.pem \
  --from-file=truststore.pem=./certs/ca-cert.pem
```

### Option 2: Inline Certificates (portal-dist Style)

**Best for**: Compatibility with portal-dist Docker Swarm deployments.

```yaml
kafka:
  tls:
    enabled: true
    type: PEM
    clientAuth: required
    # Pass certificates directly as values (base64 or PEM format)
    truststoreCertContent: |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKL...
      -----END CERTIFICATE-----
    keystoreKeyContent: |
      -----BEGIN ENCRYPTED PRIVATE KEY-----
      MIIFHDBOBgkqhkiG9w0BBQ0w...
      -----END ENCRYPTED PRIVATE KEY-----
```

**From portal-dist env file:**
```yaml
kafka:
  tls:
    enabled: true
    truststoreCertContent: "{{ auth.TSSG_TRUSTSTORE_CERT }}"
    keystoreKeyContent: "{{ auth.TSSG_CA_P8_KEY }}"
```

### Option 3: CA Certificates (analytics_util Style)

**Best for**: Compatibility with analytics_util reference implementation.

```yaml
kafka:
  tls:
    enabled: true
    type: PEM
    caKey: "{{ auth.TSSG_CA_KEY }}"
    caCertificate: "{{ auth.TSSG_SSL_CERT }}"
    caTruststoreCertificate: "{{ auth.TSSG_TRUSTSTORE_CERT }}"
```

---

## Portal-dist Compatibility Configuration

To match portal-dist Docker Swarm deployment:

```yaml
kafka:
  global:
    subdomainPrefix: "dev-portal"  # Your portal subdomain
  
  image:
    kafka: kafka:5.4
  
  kafka:
    replicaCount: 1
    
    kraft:
      enabled: true
      processRoles: "broker,controller"
      nodeId: "0"  # Single node
      controllerQuorumVoters: "0@localhost:9093"
    
    listeners:
      internal:
        enabled: true
        port: 9092
        protocol: PLAINTEXT
      external:
        enabled: true
        port: 9094
        protocol: SSL
      controller:
        enabled: true
        port: 9093
        protocol: PLAINTEXT
      interBrokerListenerName: INTERNAL
    
    # Custom advertised listeners (portal-dist format)
    advertisedListeners: "INTERNAL://kafka:9092,EXTERNAL://apim-kafka.dev-portal:9094"
    
    logRetentionHours: 6
    
    tls:
      enabled: true
      type: PEM
      clientAuth: required
      # Use inline certificates from portal-dist
      truststoreCertContent: "{{ auth.TSSG_TRUSTSTORE_CERT }}"
      keystoreKeyContent: "{{ auth.TSSG_CA_P8_KEY }}"
    
    sasl:
      enabled: true
      mechanisms: PLAIN
      interBrokerProtocol: PLAIN
      jaasConfigPath: /opt/ca/kafka/config/kafka_server_jaas.conf
  
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
    hostname: "apim-kafka.dev-portal"
```

---

## Production Multi-Node Configuration

For production with 3 Kafka brokers:

```yaml
kafka:
  global:
    subdomainPrefix: "prod-portal"
  
  kafka:
    replicaCount: 3
    
    kraft:
      enabled: true
      processRoles: "broker,controller"
      # controllerQuorumVoters auto-generated:
      # "0@kafka-0.kafka:9093,1@kafka-1.kafka:9093,2@kafka-2.kafka:9093"
    
    resources:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi
    
    tls:
      enabled: true
      type: PEM
      clientAuth: required
      secretName: kafka-tls-secret
    
    sasl:
      enabled: true
      mechanisms: PLAIN
      interBrokerProtocol: PLAIN
  
  persistence:
    storage:
      kafka: 50Gi
  
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
    # Static IPs for each broker
    loadBalancerIPs:
      - 10.0.0.100
      - 10.0.0.101
      - 10.0.0.102
```

---

## Environment Variables Reference

### Core Variables (Always Set)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `SERVICE_NAME` | Auto-generated | `kafka` or `portal-kafka` |
| `KAFKA_CFG_LOG_RETENTION_HOURS` | `kafka.logRetentionHours` | `6` |

### KRaft Mode Variables (kraft.enabled: true)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `KAFKA_CFG_NODE_ID` | `kafka.kraft.nodeId` or pod ordinal | `0` |
| `KAFKA_CFG_PROCESS_ROLES` | `kafka.kraft.processRoles` | `broker,controller` |
| `KAFKA_CFG_CONTROLLER_LISTENER_NAMES` | Fixed | `CONTROLLER` |
| `KAFKA_CFG_CONTROLLER_QUORUM_VOTERS` | `kafka.kraft.controllerQuorumVoters` or auto | `0@kafka-0.kafka:9093` |
| `KAFKA_CFG_LISTENERS` | Auto from listeners config | `INTERNAL://0.0.0.0:9092,EXTERNAL://0.0.0.0:9094,CONTROLLER://0.0.0.0:9093` |
| `KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP` | Auto from listeners config | `INTERNAL:PLAINTEXT,EXTERNAL:SSL,CONTROLLER:PLAINTEXT` |
| `KAFKA_CFG_INTER_BROKER_LISTENER_NAME` | `kafka.listeners.interBrokerListenerName` | `INTERNAL` |
| `KAFKA_CFG_ADVERTISED_LISTENERS` | `kafka.advertisedListeners` or auto | `INTERNAL://kafka:9092,EXTERNAL://apim-kafka.domain:9094` |
| `KAFKA_CLUSTER_ID` | `kafka.kraft.clusterId` (optional) | `apim-kafka` |

### TLS/SSL Variables (tls.enabled: true)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `KAFKA_TLS_TYPE` | `kafka.tls.type` | `PEM` |
| `KAFKA_CFG_SSL_CLIENT_AUTH` | `kafka.tls.clientAuth` | `required` |
| `KAFKA_CFG_SSL_KEYSTORE_TYPE` | `kafka.tls.type` | `PEM` |
| `KAFKA_CFG_SSL_TRUSTSTORE_TYPE` | `kafka.tls.type` | `PEM` |
| `KAFKA_CFG_SSL_TRUSTSTORE_CERTIFICATES` | `kafka.tls.truststoreCertContent` | `-----BEGIN CERTIFICATE-----...` |
| `KAFKA_CFG_SSL_KEYSTORE_KEY` | `kafka.tls.keystoreKeyContent` | `-----BEGIN ENCRYPTED PRIVATE KEY-----...` |
| `KAFKA_CA_KEY` | `kafka.tls.caKey` | `-----BEGIN PRIVATE KEY-----...` |
| `KAFKA_CA_CERTIFICATE` | `kafka.tls.caCertificate` | `-----BEGIN CERTIFICATE-----...` |
| `KAFKA_CA_TRUSTSTORE_CERTIFICATE` | `kafka.tls.caTruststoreCertificate` | `-----BEGIN CERTIFICATE-----...` |

### SASL Variables (sasl.enabled: true)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `KAFKA_CFG_SASL_ENABLED_MECHANISMS` | `kafka.sasl.mechanisms` | `PLAIN` |
| `KAFKA_CFG_SASL_MECHANISM_INTER_BROKER_PROTOCOL` | `kafka.sasl.interBrokerProtocol` | `PLAIN` |
| `KAFKA_CFG_OPTS` | `kafka.sasl.jaasConfigPath` | `-Djava.security.auth.login.config=/opt/ca/kafka/config/kafka_server_jaas.conf` |

### Portal Variables

| Variable | Source | Example Value |
|----------|--------|---------------|
| `APIM_PORTAL_SUBDOMAIN` | `global.subdomainPrefix` | `dev-portal` |

---

## Migration from portal-dist

### Step 1: Extract Current Configuration

From your portal-dist `env-kafka` file:

```bash
SERVICE_NAME=kafka
APIM_PORTAL_SUBDOMAIN=dev-portal
KAFKA_CFG_LOG_RETENTION_HOURS=6
KAFKA_CFG_NODE_ID=0
KAFKA_CFG_PROCESS_ROLES=broker,controller
KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@localhost:9093
KAFKA_CFG_LISTENERS=INTERNAL://0.0.0.0:9092,EXTERNAL://0.0.0.0:9094,CONTROLLER://0.0.0.0:9093
KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:SSL,CONTROLLER:PLAINTEXT
KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:9092,EXTERNAL://apim-kafka.dev-portal:9094
KAFKA_CFG_INTER_BROKER_LISTENER_NAME=INTERNAL
KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
KAFKA_TLS_TYPE=PEM
KAFKA_CFG_SSL_CLIENT_AUTH=required
KAFKA_CFG_SASL_ENABLED_MECHANISMS=PLAIN
KAFKA_CFG_SASL_MECHANISM_INTER_BROKER_PROTOCOL=PLAIN
KAFKA_CFG_OPTS=-Djava.security.auth.login.config=/opt/ca/kafka/config/kafka_server_jaas.conf
KAFKA_CFG_SSL_KEYSTORE_TYPE=PEM
KAFKA_CFG_SSL_TRUSTSTORE_TYPE=PEM
KAFKA_CFG_SSL_TRUSTSTORE_CERTIFICATES={{ auth.TSSG_TRUSTSTORE_CERT }}
KAFKA_CFG_SSL_KEYSTORE_KEY={{ auth.TSSG_CA_P8_KEY }}
```

### Step 2: Create Helm Values

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
      jaasConfigPath: /opt/ca/kafka/config/kafka_server_jaas.conf
  
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    port: 9094
    hostname: "apim-kafka.dev-portal"
```

### Step 3: Deploy

```bash
helm install portal ./charts/portal -f my-kafka-values.yaml
```

---

## Troubleshooting

### Issue: Certificates Not Working

**Symptom**: SSL handshake failures

**Solution**: Verify certificate format
```bash
# Check if certificates are base64 encoded
echo "$KAFKA_CFG_SSL_TRUSTSTORE_CERTIFICATES" | base64 -d | openssl x509 -text

# Or check if they're already PEM
echo "$KAFKA_CFG_SSL_TRUSTSTORE_CERTIFICATES" | openssl x509 -text
```

### Issue: Advertised Listeners Not Resolving

**Symptom**: Clients can't connect to external listener

**Solution**: Verify DNS and advertised listeners
```bash
# Check external service
kubectl get svc kafka-0-external

# Check advertised listeners in pod
kubectl exec kafka-0 -- env | grep ADVERTISED_LISTENERS

# Test DNS resolution
nslookup apim-kafka.dev-portal
```

### Issue: Node ID Conflicts

**Symptom**: KRaft quorum errors

**Solution**: Ensure unique node IDs
```bash
# Check node IDs
kubectl exec kafka-0 -- env | grep NODE_ID
kubectl exec kafka-1 -- env | grep NODE_ID

# Should be 0, 1, 2, etc.
```

---

## Examples

### Development (Minimal Security)

```yaml
kafka:
  kafka:
    replicaCount: 1
    kraft:
      enabled: true
    tls:
      enabled: false  # Plaintext only
    sasl:
      enabled: false
  externalAccess:
    enabled: false
```

### Staging (TLS Only)

```yaml
kafka:
  kafka:
    replicaCount: 1
    tls:
      enabled: true
      clientAuth: none  # TLS but no mTLS
      secretName: kafka-tls-secret
    sasl:
      enabled: false
  externalAccess:
    enabled: true
```

### Production (Full Security)

```yaml
kafka:
  kafka:
    replicaCount: 3
    tls:
      enabled: true
      clientAuth: required  # mTLS
      secretName: kafka-tls-secret
    sasl:
      enabled: true
      mechanisms: SCRAM-SHA-512
  externalAccess:
    enabled: true
    serviceType: LoadBalancer
    loadBalancerIPs:
      - 10.0.0.100
      - 10.0.0.101
      - 10.0.0.102
```

---

## See Also

- [README.md](README.md) - General Kafka subchart documentation
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [KAFKA_ENV_COMPARISON.md](../../KAFKA_ENV_COMPARISON.md) - Comparison with portal-dist
- [KAFKA_MIGRATION_GUIDE.md](../../KAFKA_MIGRATION_GUIDE.md) - Migration from Bitnami

