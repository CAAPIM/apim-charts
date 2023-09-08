OTK Gateway Deployment Examples
These examples cover different ways in which OTK can be deployed on Gateway using Gateway Helm Chart.
At a high level the deployment can be categorized based on Gateway type (database backed/Ephemeral) and OTK Type (SINGLE/INTERNAL/DMZ). It determines how the OTK is installed or upgraded on the gateway.
OTK installation involves
1.	Installation or upgrade of solution kit.
2.	Installation or upgrade of OTK Database.
3.	Installation or upgrade of customizations. 
Installation or Upgrade of OTK Database.
OTK database can be upgraded using gateway helm chart. Liquibase scripts are used to upgrade the database. This is not applicable for Cassandra database. At this point, OTK Cassandra database needs to be upgraded manually.
Gateway chart uses a job to upgrade the database. This can be disabled if needed.

	Database backed Gateway	Ephemeral	
SINGLE			
INTERANL			
DMZ/EDGE	NA	NA	
 
