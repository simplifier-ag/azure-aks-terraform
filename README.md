# Simplifier on AKS

**work in progress!**

## Prepare

Install prerequisites:

```shell
$ brew install azure-cli git helm kubectl terraform 
```

Initialize:

```shell
$ terraform init -upgrade
```

Upgrade provider:

```shell
$ terraform init -migrate-state -upgrade
```

Authenticate for `API` use:

```shell
$ az login
The default web browser has been opened at https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize. Please continue the login in the web browser. If no web browser is available or if the webbrowser fails to open, use device code flow with `az login --use-device-code`.
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "6455a615-e9fb-4961-83f3-102938471629",
    "id": "7b1e7ea6-c85c-4cb9-b358-678351678291",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Standard Simplifer Subscription",
    "state": "Enabled",
    "tenantId": "6455a615-e9fb-4961-83f3-968573625817",
    "user": {
      "name": "devop@simplifier.io",
      "type": "user"
    }
  }
]
```

If the cluster is up already you can simply get it's configuration:

```shell
$ az aks get-credentials --resource-group aks-testing-dev-rg --name aks-testing-dev --file .kubeconfig
```

Please adjust the parameters accordingly if required.

```
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.4", GitCommit:"b695d79d4f967c403a96986f1750a35eb75e75f1", GitTreeState:"clean", BuildDate:"2021-11-17T15:41:42Z", GoVersion:"go1.16.10", Compiler:"gc", Platform:"darwin/arm64"}
Server Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.2", GitCommit:"32a137c122b0474c719988922410f4027a4b002e", GitTreeState:"clean", BuildDate:"2021-11-01T16:43:17Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"linux/amd64"}
```

The output will only have a `Server Version` line if the cluster is accessible.

### Traefik Dashboard

```shell
$ kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -n traefik) 9000:9000 -n traefik
````

---

```shell
kubectl port-forward (kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -n traefik) 9000:9000 -n traefik

#

kubectl delete -n traefik IngressRoute traefik-dashboard
kubectl delete -n testing-dev Ingress simplifier-traefik-ingress

#

helm delete -n traefik traefik

kubectl delete -n testing-dev Middleware simplifier-middleware
kubectl delete -n testing-dev IngressRoute simplifier-route
kubectl delete -n testing-dev IngressRoute simplifier-route-tls
kubectl delete -n testing-dev Ingress simplifier-ingress
kubectl delete -n testing-dev Certificate simplifier-certificate

helm delete -n cert-manager cert-manager
kubectl delete ClusterIssuer simplifier-cluster-issuer

#

terraform apply -target=azurerm_kubernetes_cluster.aks_cluster
terraform apply -auto-approve -target=local_file.aks_kubeconfig
terraform apply -auto-approve -target=helm_release.helm_cert_manager
terraform apply -auto-approve -target=helm_release.helm_traefik
terraform apply

#

terraform state rm kubernetes_ingress.simplifier_traefik_ingress kubernetes_manifest.simplifier_middleware kubernetes_manifest.simplifier_route kubernetes_namespace.simplifier_namespace kubernetes_pod_disruption_budget.simplifier_pdb kubernetes_secret.simplifier_secret kubernetes_secret.simplifier_secret kubernetes_service.simplifier_service kubernetes_stateful_set.simplifier_stateful_set
```