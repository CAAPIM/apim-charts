#!/bin/bash

values=(adminEmail auditLogLevel multiclusterEnabled noReplyEmail performanceLogLevel portalLogLevel portalName subdomain tenantId tenantType termOfUse)

function validate_payload() {
	for i in "${!values[@]}"; do
		key="${values[i]}"
		grep -q ${key} ${data} || error=missing
		if [ -n "$error" ]; then
			echo "${key} is missing from your payload"
			exit 1
		fi
		if [ "$key" == tenantId ]; then
			#Regex match to grab correct tenantID
			re="\"tenantId\" ?: ?\"([^\"]*)\""
			json=$(cat ${data})
			TENANTID=${key}
			if [[ ${json} =~ ${re} ]]; then
				TENANTID=${BASH_REMATCH[1]}
			fi
		fi
	done
}

function print_steps() {
	tenant_id=${TENANTID:-"tenantId"}
	domain=${enrollHost#*.}

	echo "

	The tenant has been added to the database. The tenant info can be found in the tenant_info file in the current directory.
	Please follow the rest of the instructions at TechDocs to enroll your gateway with the portal.
	(https://techdocs.broadcom.com/content/broadcom/techdocs/us/en/ca-enterprise-software/layer7-api-management/api-developer-portal/4-5/install-configure-and-upgrade/post-installation-tasks/enroll-a-ca-api-gateway.html)
			
	1. You will need to navigate to the portal at https://${tenant_id}.${domain} and create a new API PROXY. 
	2. Copy the enrollment URL
	3. Open your tenant gateway and enroll this gateway with the portal using the URL from step 2.
	"
}

function hostname_resolves() {
	if ! ping -c 2 $enrollHost &> /dev/null; then
		echo "$enrollHost is not resolvable. Please make sure this points to your portal IP address."
		exit 1
	else
	    echo "$enrollHost is reachable"
	fi
}

function retrieve_key() {
	apimKey=$(kubectl get secret $keyname -n $namespace -o 'go-template={{index .data "apim-tps.key" | base64decode | base64decode }}' 2>&1 > apim-tps.key)
	apimCert=$(kubectl get secret $keyname -n $namespace -o 'go-template={{index .data "apim-tps.crt" | base64decode | base64decode }}' 2>&1 > apim-tps.crt)

if [[ $apimKey == *"Error"* ]] || [[ $apimCert == *"Error"* ]] ; then
    echo "Please check you've set the correct key name, it should be portal-internal-secret, check tls.internalSecretName in your values file."
	cleanup
	exit 1
else
    echo "Enrollment key retrieved"
fi

}

function retrieve_enrollment_host() {
	enrollHost=$(kubectl get configmap apim-config -n $namespace -o 'go-template={{index .data "TSSG_PUBLIC_HOST" }}' 2>&1)
	enrollPort=$(kubectl get configmap apim-config -n $namespace -o 'go-template={{index .data "TSSG_PUBLIC_PORT" }}' 2>&1)

if [[ $enrollHost == *"Error"* ]] || [[ $enrollPort == *"Error"* ]] ; then
    echo "Please check you've set the correct namespace and have the Chart installed"
	exit 1
else
    echo "your enrollment endpoint is https://$enrollHost:$enrollPort/provision/tenants"
fi

}

function cleanup() {
	rm apim-tps.key
	rm apim-tps.crt
}

function create_tenant() {
		STATUSCODE=$(curl --silent --output tenant_info.json --write-out "%{http_code}" \
			-X POST -k https://$enrollHost:$enrollPort/provision/tenants \
			--cert ./apim-tps.crt --key ./apim-tps.key -H "Accept: application/json" \
			-H "Content-Type: application/json" -d @${data})
		if test $STATUSCODE -ne 201; then
		    message=$(cat tenant_info.json)
		    echo ""
			echo $message
			echo ""
			cleanup
			exit 1
		else
			print_steps
		fi
}

function usage(){
		echo ""
		echo "Usage:"
		echo "-d *required enrollment payload see creating a tenant"
		echo "-k portal internal certificate secret name (default: portal-internal-secret)"
		echo "-n the namespace that you deployed the Portal into (default: default)"
		echo "    ./create_tenant.sh -d enroll.json -k <portal-internal-secret> -n kubernetesNamespace."
		echo ""
		exit 0
}

function main() {

	if [[ -z "$1" ]]; then
       usage
	else
		# Check parameters
		while getopts "d:k:n:" opt; do
			case ${opt} in
			d)
				data=$OPTARG
				if [ -f $OPTARG ];
				then data=$OPTARG
				else
				echo "please specify a valid path to your enrollment payload"
				exit 1
				fi
				;;
			k)
				keyname=$OPTARG
				;;
			n)
				namespace=$OPTARG
				;;
			*)
		      usage
				;;
			esac
		done
	fi

	if [ -z "$namespace" ]; then
		namespace="default"
	fi

	if [ -z "$keyname" ]; then
		keyname="portal-internal-secret"
	fi

	validate_payload
	retrieve_enrollment_host
	hostname_resolves
	retrieve_key
	create_tenant
	cleanup
}

main "$@"
