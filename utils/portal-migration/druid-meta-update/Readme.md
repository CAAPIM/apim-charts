# Portal Druid Metadata Update

## Allows users to update the bucket metrics are stored in.
If migrating from Docker Swarm to Kubernetes, or on-prem analytics storage to Cloud it's necessary to update the bucket name Druid will rebuild it's index from.

### Input Variables:
  - `MYSQL_USERNAME`
  - `MYSQL_PASSWORD`
  - `MYSQL_HOST`
  - `MYSQL_PORT`
  - `DATABASE_NAME`
  - `BUCKET_NAME`

***This is only required if customers need to change reference to druid.minio.bucketName - in most cases it will not be run.***

## Usage

### On a machine that has Docker and access to the Portal MySQL database
  - ```$ curl https://raw.githubusercontent.com/CAAPIM/apim-charts/stable/utils/portal-migration/druid-meta-update/druid-meta-update.sh > druid-meta-update.sh```
  - ```$ chmod +x druid-meta-update.sh```
  - ```$ ./druid-meta-update.sh -h <mysql-host> -P <mysql-port> -u <mysql-username> -b <bucket-name> -d <database-name>|default druid```