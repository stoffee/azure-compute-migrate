terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate a random suffix for uniqueness
# Because nobody likes that "name already taken" error! 😅
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group - Our cozy little home in Azure
resource "azurerm_resource_group" "test" {
  name     = "rg-test-migration-${random_string.suffix.result}"
  location = "westus"  # West US, where dreams come true! ✨
  
  tags = {
    environment = "test"
    purpose     = "migration-testing"
    mood        = "playful"
  }
}

# Virtual Network - Like a digital neighborhood
resource "azurerm_virtual_network" "test" {
  name                = "vnet-test-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.0.0.0/16"]  # Plenty of IP addresses to go around!

  tags = {
    environment = "test"
    purpose     = "migration-testing"
    status      = "feeling-networky"
  }
}

# Subnets - Like little digital cul-de-sacs
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group - The bouncer at the digital club 🚫
resource "azurerm_network_security_group" "test" {
  name                = "nsg-test-${random_string.suffix.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  # Allow SSH - Because we're not savages!
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "test"
    purpose     = "migration-testing"
    security    = "fort-knox-junior"
  }
}

# Private DNS Zone - Because even test environments deserve fancy names
resource "azurerm_private_dns_zone" "test" {
  name                = "test.migration.local"
  resource_group_name = azurerm_resource_group.test.name

  tags = {
    environment = "test"
    purpose     = "migration-testing"
    dns_mood    = "feeling-resolvy"
  }
}

# Link the DNS Zone to the VNet - Making introductions!
resource "azurerm_private_dns_zone_virtual_network_link" "test" {
  name                  = "dns-vnet-link-${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.test.name
  private_dns_zone_name = azurerm_private_dns_zone.test.name
  virtual_network_id    = azurerm_virtual_network.test.id
  registration_enabled  = true
}

# Outputs - Because we like to know what we built!
output "resource_group_name" {
  value = azurerm_resource_group.test.name
}

output "vnet_name" {
  value = azurerm_virtual_network.test.name
}

output "private_dns_zone" {
  value = azurerm_private_dns_zone.test.name
}
