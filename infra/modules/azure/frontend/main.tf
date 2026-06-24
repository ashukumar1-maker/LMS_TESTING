locals {
  compact_prefix     = substr(replace(lower(var.name_prefix), "/[^a-z0-9]/", ""), 0, 34)
  custom_domain_name = substr(replace(lower(var.domain_name), "/[^a-z0-9-]/", "-"), 0, 60)
  endpoint_name      = substr("${local.compact_prefix}${var.suffix}fd", 0, 46)

  tags = {
    environment = var.environment
    project     = var.project_id
    managed-by  = "terraform"
  }
}

resource "azurerm_cdn_frontdoor_profile" "frontend" {
  name                = "${var.name_prefix}-frontend-fd"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = local.tags
}

resource "azurerm_storage_account_static_website" "frontend" {
  storage_account_id = var.storage_account_id
  index_document     = "index.html"
  error_404_document = "index.html"
}

data "azurerm_storage_account" "frontend" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_storage_account_static_website.frontend]
}

resource "azurerm_cdn_frontdoor_endpoint" "frontend" {
  name                     = local.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontend.id
  enabled                  = true

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "frontend" {
  name                     = "frontend-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontend.id

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "frontend" {
  name                          = "frontend-storage"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = data.azurerm_storage_account.frontend.primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = data.azurerm_storage_account.frontend.primary_web_host
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_custom_domain" "frontend" {
  name                     = local.custom_domain_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontend.id
  host_name                = var.domain_name

  tls {
    certificate_type = "ManagedCertificate"
    minimum_version  = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "frontend" {
  name                          = "frontend-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontend.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontend.id]
  enabled                       = true

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.frontend.id]
  forwarding_protocol             = "HttpsOnly"
  https_redirect_enabled          = true
  link_to_default_domain          = true
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]

  cache {
    compression_enabled = true
    content_types_to_compress = [
      "application/eot",
      "application/font",
      "application/font-sfnt",
      "application/javascript",
      "application/json",
      "application/opentype",
      "application/otf",
      "application/pkcs7-mime",
      "application/truetype",
      "application/ttf",
      "application/vnd.ms-fontobject",
      "application/xhtml+xml",
      "application/xml",
      "application/xml+rss",
      "font/eot",
      "font/otf",
      "font/ttf",
      "image/svg+xml",
      "text/css",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/xml",
    ]
    query_string_caching_behavior = "IgnoreQueryString"
  }
}
