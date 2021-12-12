terraform {
  required_version = ">= 1.0.10"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    # https://registry.terraform.io/providers/hashicorp/azurerm/latest
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.89.0"
    }
    # https://registry.terraform.io/providers/microsoft/azuredevops/latest
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.1.8"
    }
    # https://registry.terraform.io/providers/hashicorp/helm/latest
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
  }

  backend "azurerm" {
    subscription_id      = "7b1e7ea6-c85c-4cb9-b358-fa9d61807ce7"
    resource_group_name  = "terraform-aks"
    storage_account_name = "terraformaksstates"
    container_name       = "terraform"
    key                  = "aks.tfstate"
  }
}

provider "azurerm" {
  subscription_id = local.settings.subscription_id
  features {}
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/simplifierag"
}

# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
# }

provider "kubernetes" {
  config_path = ".kubeconfig"
}

# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
#   }
# }

provider "helm" {
  kubernetes {
    config_path = ".kubeconfig"
  }
}
