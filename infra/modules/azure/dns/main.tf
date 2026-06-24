locals {
  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }

  dnssec_delegation_signer_info = flatten([
    for signing_key in try(azapi_resource.dnssec.output.properties.signingKeys, []) : [
      for signer_info in try(signing_key.delegationSignerInfo, []) : {
        key_tag               = signing_key.keyTag
        algorithm             = signing_key.securityAlgorithmType
        digest_algorithm_type = signer_info.digestAlgorithmType
        digest_value          = signer_info.digestValue
        record                = signer_info.record
      }
    ]
  ])
}

resource "azurerm_dns_zone" "default" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azapi_resource" "dnssec" {
  type      = "Microsoft.Network/dnsZones/dnssecConfigs@2023-07-01-preview"
  name      = "default"
  parent_id = azurerm_dns_zone.default.id
  body      = {}
}

resource "azurerm_dns_a_record" "api" {
  name                = "api"
  zone_name           = azurerm_dns_zone.default.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.backend_ip_address]
}

resource "azurerm_dns_txt_record" "frontend_domain_validation" {
  name                = "_dnsauth"
  zone_name           = azurerm_dns_zone.default.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600

  record {
    value = var.frontend_custom_domain_validation_token
  }
}

resource "azurerm_dns_a_record" "frontend" {
  name                = "@"
  zone_name           = azurerm_dns_zone.default.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  target_resource_id  = var.frontend_endpoint_id

  depends_on = [
    azurerm_dns_txt_record.frontend_domain_validation,
  ]
}
