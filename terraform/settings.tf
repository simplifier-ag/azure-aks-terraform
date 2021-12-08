locals {
  default = {
    environment = terraform.workspace

    creator         = "DevOp"
    customer        = "testing"
    dns_prefix      = ""
    dns_suffix      = "aks.simplifier.io"
    image           = "simplifierag/runtime:6.5"
    linux_nodes_sku = "Standard_B4ms"
    location        = "westeurope"
    name            = ""
    os_disk_size_gb = 30
    subscription_id = ""

    # TODO: enable
    #repo_rev = trimspace(file(".git/${trimspace(trimprefix(file(".git/HEAD"), "ref:"))}"))
  }

  # ingest yaml at 'environments/workspace.yaml' for per-environment settings
  current = terraform.workspace == "default" ? local.default : merge(local.default, yamldecode(file("${path.root}/environments/${terraform.workspace}.yaml")))

  settings = {
    # compose
    name       = "aks-${local.current.customer}-${lower(local.current.environment)}"
    dns_prefix = "${local.current.customer}-${lower(local.current.environment)}"
    # copy
    creator         = local.current.creator
    customer        = local.current.customer
    dns_suffix      = local.current.dns_suffix
    environment     = local.current.environment
    image           = local.current.image
    linux_nodes_sku = local.current.linux_nodes_sku
    location        = local.current.location
    os_disk_size_gb = local.current.os_disk_size_gb
    subscription_id = local.current.subscription_id
  }
}

locals {
  # copy for tagging
  tags = {
    creator     = local.settings.creator
    customer    = local.settings.customer
    environment = lower(local.settings.environment)
    k8s-app     = "${local.current.customer}-${local.current.environment}"
  }
}