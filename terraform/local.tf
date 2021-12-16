resource "null_resource" "az_extension_add_aks_preview" {
  provisioner "local-exec" {
    command = "az extension add --name \"aks-preview\""
  }
}

resource "null_resource" "az_extension_update_aks_preview" {
  provisioner "local-exec" {
    command = "az extension update --name \"aks-preview\""
  }
}


resource "null_resource" "az_feature_encryption_at_host" {
  provisioner "local-exec" {
    command = "az feature register --namespace \"Microsoft.Compute\" --name \"EncryptionAtHost\""
  }
}

resource "null_resource" "az_feature_custom_node_config_preview" {
  provisioner "local-exec" {
    command = "az feature register --namespace \"Microsoft.ContainerService\" --name \"CustomNodeConfigPreview\""
  }
}

resource "null_resource" "az_feature_allow_multiple_address_prefixes_on_subnet" {
  provisioner "local-exec" {
    command = "az feature register --namespace \"Microsoft.Network\" --name \"AllowMultipleAddressPrefixesOnSubnet\""
  }
}

resource "null_resource" "az_feature_pod_security_policy_preview" {
  provisioner "local-exec" {
    command = "az feature register --namespace \"Microsoft.ContainerService\" --name \"PodSecurityPolicyPreview\""
  }
}

# resource "null_resource" "az_feature_aks_natgateway_preview" {
#   provisioner "local-exec" {
#     command = "az feature register --namespace \"Microsoft.ContainerService\" --name \"AKS-NATGatewayPreview\""
#   }
# }

resource "null_resource" "az_provider_register_container_service" {
  provisioner "local-exec" {
    command = "az provider register --namespace \"Microsoft.ContainerService\""
  }
}


resource "null_resource" "az_provider_register_namespace" {
  provisioner "local-exec" {
    command = "az provider register --namespace \"Microsoft.Network\""
  }
}

resource "null_resource" "az_provider_register_microsoft_policy_insights" {
  provisioner "local-exec" {
    command = "az provider register --namespace \"Microsoft.PolicyInsights\""
  }
}
