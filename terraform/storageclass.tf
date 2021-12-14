resource "kubernetes_storage_class" "simplifier_ultra" {
  metadata {
    name   = "simplifier-ultra"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  reclaim_policy      = "Delete"
  parameters = {
    # https://github.com/kubernetes/kubernetes/issues/103433#issuecomment-873058843
    kind              = "Managed"
    skuname           = "UltraSSD_LRS"
    cachingmode       = "None"
    volumeBindingMode = "WaitForFirstConsumer"
    diskIopsReadWrite = "2000"
    diskMbpsReadWrite = "320"
  }
}

resource "kubernetes_storage_class" "simplifier_xfs" {
  metadata {
    name   = "simplifier-xfs"
    labels = local.tags
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  reclaim_policy      = "Delete"
  parameters = {
    # https://github.com/kubernetes/kubernetes/issues/103433#issuecomment-873058843
    kind              = "Managed"
    skuname           = "Standard_LRS"
    cachingmode       = "None"
    volumeBindingMode = "WaitForFirstConsumer"
    fstype            = "xfs"
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
    # https://docs.microsoft.com/en-us/azure/aks/azure-files-csi#dynamically-create-azure-files-pvs-by-using-the-built-in-storage-classes
    skuname = "Standard_LRS"
  }
  mount_options = ["file_mode=0666", "dir_mode=0777", "uid=0", "gid=0", "cache=strict", "actimeo=30"]
}

resource "kubernetes_storage_class" "simplifier_nfs" {
  metadata {
    name   = "simplifier-nfs"
    labels = local.tags
  }
  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  parameters = {
    # https://docs.microsoft.com/en-us/azure/aks/azure-files-csi#dynamically-create-azure-files-pvs-by-using-the-built-in-storage-classes
    protocol = "nfs"
  }
}

# resource "kubernetes_storage_class" "simplifier_certs" {
#   metadata {
#     name   = "simplifier-certs"
#     labels = local.tags
#   }
#   storage_provisioner = "kubernetes.io/azure-file"
#   reclaim_policy      = "Delete"
#   parameters = {
#     skuname = "Standard_LRS"
#   }
#   mount_options = ["file_mode=0600", "dir_mode=0700", "uid=0", "gid=0", "cache=strict", "actimeo=30"]
# }
