# AKS

**work in progress!**

## Role

Install prerequisites:

```shell
$ brew install azure-cli helm kubectl terraform 
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

TODO

```
terraform state rm "kubernetes_namespace.simplifier" "kubernetes_storage_class.simplifier" "kubernetes_secret.simplifier" "kubernetes_service.simplifier" "kubernetes_ingress.simplifier" "kubernetes_stateful_set.simplifier" "helm_release.helm_traefik" "helm_release.helm_cert_manager" "kubernetes_storage_class.simplifier-many" "kubernetes_storage_class.simplifier-ultra" "kubernetes_pod_disruption_budget.simplifier"
```

*** Service Principal

```shell
$ openssl req -x509 -days 3650 -newkey rsa:2048 -out principal_cert.pem -nodes -subj '/CN=simplifier-aks' > principal_secret.key
```
