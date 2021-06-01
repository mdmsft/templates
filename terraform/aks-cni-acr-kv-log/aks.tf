terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.60.0"
    }
  }
  backend "azurerm" {
    # resource_group_name  = "..."
    # storage_account_name = "..."
    # container_name       = "tfstate"
    key                  = "fabrikam.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "ssh_key_path" {
  type = string
}

variable "aad_admin_group_id" {
  type = string
}

locals {
  project  = "fabrikam"
  location = "West Europe"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project}"
  location = local.location
}

resource "azurerm_user_assigned_identity" "id" {
  name                = "id-${local.project}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.project}"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "snet_srv" {
  name                 = "snet-srv-${local.project}"
  address_prefixes     = ["10.0.0.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

resource "azurerm_subnet" "snet_aks" {
  name                 = "snet-aks-${local.project}"
  address_prefixes     = ["10.0.1.0/24"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.project}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = var.tenant_id
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  sku_name                   = "standard"

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    virtual_network_subnet_ids = [azurerm_subnet.snet_srv.id]
  }
}

resource "azurerm_role_assignment" "rbac_id_kv" {
  principal_id                     = azurerm_user_assigned_identity.id.principal_id
  role_definition_name             = "Key Vault Reader"
  skip_service_principal_aad_check = false
  scope                            = azurerm_key_vault.kv.id
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-${local.project}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  daily_quota_gb      = 30
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.project}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  default_node_pool {
    name                = "system"
    node_count          = 2
    vm_size             = "standard_f2s_v2"
    enable_auto_scaling = true
    max_count           = 4
    min_count           = 2
    max_pods            = 64
    vnet_subnet_id      = azurerm_subnet.snet_aks.id
    os_disk_type        = "Ephemeral"
    os_disk_size_gb     = 32

    upgrade_settings {
      max_surge = "50%"
    }
  }

  addon_profile {
    azure_policy {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id
    }
  }

  dns_prefix = local.project

  automatic_channel_upgrade = "rapid"

  identity {
    type = "SystemAssigned"
  }

  kubernetes_version = "1.20.5"

  linux_profile {
    admin_username = local.project

    ssh_key {
      key_data = file(var.ssh_key_path)
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.0.3.254"
    service_cidr       = "10.0.3.0/24"
    docker_bridge_cidr = "172.17.0.1/24"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      azure_rbac_enabled     = true
      managed                = true
      admin_group_object_ids = [var.aad_admin_group_id]
    }
  }
}

resource "azurerm_container_registry" "cr" {
  name                = "cr${local.project}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_enabled       = true

  network_rule_set = [{
    default_action = "Allow"
    ip_rule = [{
      action   = "Allow"
      ip_range = "90.60.90.0/24"
    }]
    virtual_network = [{
      action    = "Allow"
      subnet_id = azurerm_subnet.snet_srv.id
    }]
  }]

  retention_policy {
    enabled = true
    days    = 7
  }

  trust_policy {
    enabled = true
  }

  public_network_access_enabled = true
  quarantine_policy_enabled     = true
  sku                           = "Premium"
}

resource "azurerm_role_assignment" "rbac_aks_cr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = false
  scope                            = azurerm_container_registry.cr.id
}
