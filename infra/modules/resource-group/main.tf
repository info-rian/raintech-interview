locals {
  name = "${var.project_name}-${var.environment}-rg-01"
}

resource "azurerm_resource_group" "this" {
  name     = local.name
  location = var.location

  tags = merge(
    var.tags,
    {
      Name        = local.name
      Kind        = "foundation"
      Environment = var.environment
    }
  )
}
