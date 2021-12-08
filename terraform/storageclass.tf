# resource "kubernetes_storage_class" "simplifier-ultra" {
#   metadata {
#     name   = "simplifier-ultra"
#     labels = local.tags
#   }
#   storage_provisioner = "kubernetes.io/azure-disk"
#   reclaim_policy      = "Delete"
#   parameters = {
#     cachingmode       = "None"
#     kind              = "managed"
#     skuname           = "UltraSSD_LRS"
#     diskIopsReadWrite = "2000"
#     diskMbpsReadWrite = "320"
#   }
# }

resource "kubernetes_storage_class" "simplifier-many" {
  metadata {
    name   = "simplifier-many"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
  parameters = {
    skuname = "Standard_LRS"
  }
  mount_options = ["file_mode=0666", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict", "actimeo=30"]
}
