## APIM Helm Charts
This repository contains a series of Helm Charts for the Layer7 API Management (APIM) Portfolio.


## Usage
Helm Charts are essentially 'packaged applications' that describe how the APIM solution shall be built in a Kubernetes cluster. Navigate into the Chart you'd like to deploy for more details. 

Learn [why](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/congw-10-0/install-configure-upgrade/configuring-the-container-gateway.html) Layer7 recommends the Helm Chart for quickly deploying an APIM solution (e.g., the API Gateway) to Kubernetes. 

## Helm Charts

- gateway-sts: Helm Chart for deploying API Gateway - OAUTH TOOLKIT
- gateway: Helm Chart for deploying API Gateway

The ./examples contain individual readme files for each deployment scenario.

## Before You Start
First we need to download the dependent charts.

`$ helm dep up <path_to_the_gateway_chart>`

You should see a commandline output similar to this,

>Saving 4 charts<br/>
>Downloading hazelcast from repo https://hazelcast-charts.s3.amazonaws.com/<br/>
>Downloading influxdb from repo https://helm.influxdata.com/<br/>
>Downloading grafana from repo https://charts.bitnami.com/bitnami<br/>
>Downloading mysql from repo https://kubernetes-charts.storage.googleapis.com<br/>
>

## Note
This Helm Chart was created by Layer7 Broadcom.

All Chart configurations referenced on this repository and other Layer7 APIM documentation are configurable via a <i>values.yaml</i> file. The samples provided in this repository can be used as a starting point to configure your installation for a production scenario.
