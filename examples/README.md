# Examples
This folder contains information on how to deploy the various apim-charts with different configurations.

## Prerequisite:
* Helm 3.x
* The Kubernetes CLI (kubectl)
* A Gateway license - not required for Portal examples.


## Gateway Examples
The Gateway Chart is comprised of the base Layer7 API Gateway, MySQL, Hazelcast, InfluxDb and Grafana. It contains a reference implementation that you can use
as an example to get a feel for what's possible and where to start when externalising Hazelcast or Offboxing Service Metrics to InfluxDb and visualising them in Grafana.

Start by cloning [values.yaml](../charts/gateway/values.yaml) onto a machine that has Helm v3.x and kubectl installed with access to a kubernetes cluster. You can also use ```curl``` to do this

```$ curl https://raw.githubusercontent.com/CAAPIM/apim-charts/master/charts/gateway/values.yaml > my-values.yaml```

Next add the layer7 Helm Chart Repository if you haven't already

``` $ helm repo add layer7 https://caapim.github.io/apim-charts/```

``` $ helm repo update ```

* [Gateway with Sub-Charts](#gateway-with-subcharts)
* [Gateway with Ingress Controller (nginx)](#gateway-with-ingress-controller)


### Gateway with SubCharts
Here we'll enable all of the Gateway sub-charts, you can pick and choose which you'd like to try.

***Note:*** Offboxing Service Metrics requires InfluxDb, Grafana and ServiceMetrics to be enabled. Hazelcast does not require any of these.

1. Open the ***my-values.yaml*** that you saved earlier
   - Update the following values in this file.
     ```
      management.restman.enabled: true  ==> this optionally enables restman, you can skip this if you don't need it
      management.username: admin        ==> default PM username
      management.password: mypassword   ==> default PM password
      serviceMetrics.enabled: true      ==> this deploys an example service metrics policy to your Gateway [click here for more info](https://techdocs.broadcom.com/us/en/ca-enterprise-software/layer7-api-management/api-gateway/10-0/learning-center/overview-of-the-policy-manager/gateway-dashboard/configure-gateway-for-external-service-metrics.html)
      hazelcast.enabled: true           ==> deploys a pre-configured hazelcast
      influxdb.enabled: true            ==> deploys influxdb
      grafana.enabled: true             ==> deploys grafana
      grafana.customDashboard.value     ==> use --set-file to specify your own grafana dashboard (optional)
     ```
2. Install the Gateway Chart
   - ```$ helm install <release-name> --set license.accept=true --set-file license.value=/path/to/license.xml -f /path/to/my-values.yaml -n <namespace> layer7/gateway```

3. Get the Gateway IP Address for Policy Manager (admin/mypassword are the default login credentials)
   - ```$ kubectl get svc -n <namespace> | grep <release-name>``` ==> you should see an EXTERNAL-IP (if using minikube see ingress settings or use minikube proxy)
4. Open Policy Manager v10 and connect to your new Gateway.
5. Create a dummy API and access via curl or your browser.
4. Connect to Grafana and view your service metrics
   - ```$ kubectl port-forward svc <release-name>-grafana 3000:3000 -n <namespace>```
5. Open a browser and navigate to http://localhost:3000
   - ```username: admin``` ===> these default credentials can be updated in values.yaml
   - ```password: password```


### Gateway with Ingress Controller
Coming Soon.