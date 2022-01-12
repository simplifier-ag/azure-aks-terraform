locals {
  # FIXME: move directory around
  repo_rev = trimspace(file("../.git/${trimspace(trimprefix(file("../.git/HEAD"), "ref:"))}"))

  default = {
    environment = terraform.workspace

    name            = ""
    dns_prefix      = ""
    subscription_id = ""

    creator         = "DevOp"
    customer        = "testing"
    dns_suffix      = "aks.simplifier.io"
    dns_zone_server = "40.90.4.7"

    # FIXME: "latest" tags was not updated
    image = "simplifierag/runtime:6.5"

    maintenance_window_day   = "Tuesday"
    maintenance_window_hours = [2, 3, 4]

    # https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks#size-requirements
    # linux_nodes_sku = "Standard_B4ms"
    linux_nodes_sku = "Standard_DS3_v2"
    location        = "westeurope"
    os_disk_size_gb = 30
    aks_sku_tier    = "Free"
  }

  # ingest yaml at 'environments/workspace.yaml' for per-environment settings
  current = terraform.workspace == "default" ? local.default : merge(local.default, yamldecode(file("${path.root}/environments/${terraform.workspace}.yaml")))

  settings = {
    # compose
    name = "aks-${local.current.customer}-${lower(local.current.environment)}"

    dns_suffix      = local.current.dns_suffix
    dns_zone_server = local.current.dns_zone_server
    dns_prefix      = "${lower(local.current.customer)}-${lower(local.current.environment)}"
    fqdn            = "${lower(local.current.customer)}-${lower(local.current.environment)}.${local.current.dns_suffix}"

    # copy
    aks_sku_tier             = local.current.aks_sku_tier
    creator                  = local.current.creator
    customer                 = local.current.customer
    environment              = local.current.environment
    image                    = local.current.image
    linux_nodes_sku          = local.current.linux_nodes_sku
    location                 = local.current.location
    maintenance_window_day   = local.current.maintenance_window_day
    maintenance_window_hours = local.current.maintenance_window_hours
    os_disk_size_gb          = local.current.os_disk_size_gb
    subscription_id          = local.current.subscription_id
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

  additional_set_tags = {
    "git-rev"                         = local.repo_rev
    "addonmanager.kubernetes.io/mode" = "Reconcile"
    "kubernetes.io/cluster-service"   = "true"
  }
}
