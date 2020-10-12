## APIM Helm Charts
This repository contains a series of Helm Charts for the Layer7 API Management (APIM) Portfolio.

## Usage
Helm Charts are essentially 'packaged applications' that describe how the APIM solution shall be built in a Kubernetes cluster. Navigate into the Chart you'd like to deploy for more details. 

Learn [why](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-0/install-configure-upgrade/configuring-the-container-gateway.html) Layer7 recommends the Helm Chart for quickly deploying an APIM solution (e.g., the API Gateway) to Kubernetes. 


## Quick Start

Add the layer7 repository:

    $ helm repo add layer7 https://caapim.github.io/apim-charts/
    $ helm repo update

Then, you can install the charts by:

    $ helm install my-ssg layer7/gateway --set-file "license.value=path/to/license.xml" --set "license.accept=true""

## Helm Charts

- gateway: Helm Chart for deploying API Gateway
- gateway-otk: Helm Chart for deploying API Gateway with the OAUTH TOOLKIT


*** examples *** contains chart specific values files that you can apply to your Gateway deployment to achieve specific scenarios. Otk-scenarios is currently in an alpha state and will be updated in the coming weeks.

## Note
This Helm Chart was created by Layer7 Broadcom.

All Chart configurations referenced on this repository and other Layer7 APIM documentation are configurable via a <i>values.yaml</i> file. The samples provided in this repository can be used as a starting point to configure your installation for a production scenario.
