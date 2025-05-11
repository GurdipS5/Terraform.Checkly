locals {
  valid_locations = [
    "us-east-1",
    "us-west-1",
    "eu-west-1",
    "eu-central-1",
    "ap-southeast-1",
    "ap-southeast-2"
  ]

  # Validate locations
  location_validation = [
    for check in concat(var.api_checks, var.browser_checks) :
    [
      for location in check.locations :
      contains(local.valid_locations, location) ? location :
      file("ERROR: Invalid location ${location}. Valid locations are: ${join(", ", local.valid_locations)}")
    ]
  ]
}
