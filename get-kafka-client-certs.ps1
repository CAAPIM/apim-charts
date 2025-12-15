# Script to extract Kafka client certificates for external access
# Run this to get the certificates needed for external Kafka clients

Write-Host "=== Extracting Kafka Client Certificates ===" -ForegroundColor Green

# Create output directory
$outputDir = "kafka-client-certs"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Extract TSSG CA certificate (for truststore)
Write-Host "`n1. Extracting TSSG CA certificate..."
kubectl get secret portal-internal-secret -n mr-intel93 -o jsonpath='{.data.apim-ssl\.crt}' | ForEach-Object {
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
} | Out-File -FilePath "$outputDir\tssg-ca.crt" -Encoding ASCII
Write-Host "   Saved to: $outputDir\tssg-ca.crt"

# Extract TSSG key (can be used as client key for testing)
Write-Host "`n2. Extracting TSSG key (for client authentication)..."
kubectl get secret portal-internal-secret -n mr-intel93 -o jsonpath='{.data.apim-ssl\.key}' | ForEach-Object {
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
} | Out-File -FilePath "$outputDir\client.key" -Encoding ASCII
Write-Host "   Saved to: $outputDir\client.key"

# Copy certificate as client certificate
Copy-Item "$outputDir\tssg-ca.crt" "$outputDir\client.crt"
Write-Host "   Saved to: $outputDir\client.crt"

Write-Host "`n=== Certificates extracted successfully ===" -ForegroundColor Green
Write-Host "`nFiles created in $outputDir directory:"
Write-Host "  - tssg-ca.crt      (CA certificate for truststore)"
Write-Host "  - client.key       (Client private key)"
Write-Host "  - client.crt       (Client certificate)"

Write-Host "`n=== Java Client Configuration ===" -ForegroundColor Yellow
Write-Host @"

For Java Kafka clients, use these properties:

bootstrap.servers=10.252.148.89:9094
security.protocol=SSL
ssl.truststore.type=PEM
ssl.truststore.certificates=`$(cat $outputDir/tssg-ca.crt)
ssl.keystore.type=PEM
ssl.keystore.key=`$(cat $outputDir/client.key)
ssl.keystore.certificate.chain=`$(cat $outputDir/client.crt)
ssl.endpoint.identification.algorithm=

"@

Write-Host "=== Done ===" -ForegroundColor Green






