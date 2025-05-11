
# Existing variables remain the same...

variable "private_locations" {
  description = "Private locations to create"
  type = list(object({
    name        = string
    slug_name   = string # Unique identifier for the private location
    description = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for loc in var.private_locations : length(loc.name) >= 3 && length(loc.name) <= 64
    ])
    error_message = "Private location name must be between 3 and 64 characters."
  }

  validation {
    condition = alltrue([
      for loc in var.private_locations : can(regex("^[a-z0-9-]+$", loc.slug_name))
    ])
    error_message = "Private location slug must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "website_checks" {
  description = "Website checks to create"
  type = list(object({
    name           = string
    url            = string
    frequency      = optional(number, 10)
    locations      = optional(list(string), ["us-east-1"]) # Public locations
    private_locations = optional(list(string), [])         # Private location slugs
    retry_strategy = optional(object({
      type        = optional(string, "FIXED")
      max_retries = optional(number, 3)
    }))
    alerts = optional(object({
      ssl_expiry_threshold    = optional(number, 30)  # Days
      max_response_time       = optional(number, 10000) # ms
      degraded_response_time  = optional(number, 5000)  # ms
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for check in var.website_checks : can(regex("^https?://", check.url))
    ])
    error_message = "Website URLs must start with http:// or https://."
  }

  validation {
    condition = alltrue([
      for check in var.website_checks : check.frequency >= 1 && check.frequency <= 1440
    ])
    error_message = "Check frequency must be between 1 and 1440 minutes."
  }

  validation {
    condition = alltrue([
      for check in var.website_checks : 
        (length(coalesce(check.locations, [])) + length(coalesce(check.private_locations, []))) > 0
    ])
    error_message = "At least one location (public or private) must be specified for website checks."
  }
}
