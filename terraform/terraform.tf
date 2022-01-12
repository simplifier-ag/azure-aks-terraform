terraform {
  required_version = ">= 1.1"

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
      version = "~> 2.91.0"
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

  # TODO: can this take variables, somehow?
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

provider "kubernetes" {
  config_path = ".kubeconfig"
}

provider "helm" {
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm"
  kubernetes {
    config_path = ".kubeconfig"
  }
}
