# resource "kubernetes_storage_class" "simplifier_ultra" {
#   metadata {
#     name   = "simplifier-ultra"
#     labels = local.tags
#   }
#   storage_provisioner = "kubernetes.io/azure-disk"
#   reclaim_policy      = "Retain"
#   parameters = {
#     cachingmode       = "None"
#     kind              = "managed"
#     skuname           = "UltraSSD_LRS"
#     diskIopsReadWrite = "2000"
#     diskMbpsReadWrite = "320"
#   }
# }

resource "kubernetes_storage_class" "simplifier_xfs" {
  metadata {
    name   = "simplifier-xfs"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  reclaim_policy      = "Delete"
  parameters = {
    #cachingmode       = "None"
    kind    = "managed"
    skuname = "Standard_LRS"
    fstype  = "xfs"
  }
}

resource "kubernetes_storage_class" "simplifier_many" {
  metadata {
    name   = "simplifier-many"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Delete"
  parameters = {
    skuname = "Standard_LRS"
  }
  mount_options = ["file_mode=0666", "dir_mode=0777", "uid=0", "gid=0", "cache=strict", "actimeo=30"]
}

resource "kubernetes_storage_class" "simplifier_certs" {
  metadata {
    name   = "simplifier-certs"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Delete"
  parameters = {
    skuname = "Standard_LRS"
  }
  mount_options = ["file_mode=0600", "dir_mode=0700", "uid=0", "gid=0", "cache=strict", "actimeo=30"]
}