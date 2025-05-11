
# Private Locations
resource "checkly_private_location" "locations" {
  for_each = { for loc in var.private_locations : loc.slug_name => loc }

  name        = each.value.name
  slug_name   = each.value.slug_name
  description = each.value.description
}

# Website Checks
resource "checkly_check" "website" {
  for_each = { for idx, check in var.website_checks : check.name => check }

  name                      = each.value.name
  type                      = "BROWSER"
  activated                 = true
  should_fail              = false
  frequency                = each.value.frequency
  locations                = each.value.locations
  private_locations        = [
    for loc in each.value.private_locations : 
    checkly_private_location.locations[loc].slug_name
  ]
  tags                     = var.tags
  muted                    = var.check_defaults.muted
  double_check            = var.check_defaults.double_check
  use_global_alert_settings = var.check_defaults.use_global_alert_settings

  script = <<-EOT
    const { chromium } = require('playwright');
    
    async function run() {
      const browser = await chromium.launch();
      const page = await browser.newPage();
      
      console.log('Navigating to ${each.value.url}');
      const response = await page.goto('${each.value.url}');
      
      // Check status code
      if (!response.ok()) {
        throw new Error(`Failed to load page: ${response.status()}`);
      }
      
      // Take screenshot
      await page.screenshot({ path: 'screenshot.png' });
      
      await browser.close();
    }
    
    run();
  EOT

  retry_strategy {
    type        = each.value.retry_strategy.type
    max_retries = each.value.retry_strategy.max_retries
  }

  alert_channel_subscription {
    channel_id = values(checkly_alert_channel.channels)[*].id
    activated  = true
  }
}
