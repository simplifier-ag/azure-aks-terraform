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

Create workspace for "dev" environment:

```shell
$ terraform workspace new dev
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

## Setup

If not, we need to bring it up!

```shell
$ terraform apply -target=azurerm_kubernetes_cluster.aks_cluster
$ terraform apply -auto-approve -target=local_file.aks_kubeconfig
$ helm repo update
$ terraform apply -auto-approve -target=helm_release.helm_cert_manager
$ terraform apply -auto-approve -target=helm_release.helm_traefik
$ terraform apply
```

Now, let's check the connectivity:

```shell
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.1", GitCommit:"86ec240af8cbd1b60bcc4c03c20da9b98005b92e", GitTreeState:"clean", BuildDate:"2021-12-16T11:33:37Z", GoVersion:"go1.17.5", Compiler:"gc", Platform:"darwin/arm64"}
Server Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.4", GitCommit:"b695d79d4f967c403a96986f1750a35eb75e75f1", GitTreeState:"clean", BuildDate:"2021-11-18T19:30:35Z", GoVersion:"go1.16.10", Compiler:"gc", Platform:"linux/amd64"}
```

The output will only have a `Server Version` line if the cluster is accessible.

### Traefik Dashboard

```shell
$ kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -n traefik) 9000:9000 -n traefik
````
