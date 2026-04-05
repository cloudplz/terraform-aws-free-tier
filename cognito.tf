# Cognito — always free: 10,000 MAUs (Monthly Active Users) for direct/social sign-in
# ⚠️ Advanced security features (adaptive auth, compromised credentials) incur charges
# ⚠️ SAML/OIDC federation reduces free tier to 50 MAUs

resource "aws_cognito_user_pool" "main" {
  for_each = var.features.cognito ? { this = {} } : {}

  name = "${var.name}-user-pool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # ⚠️ Do NOT set advanced_security_mode = "ENFORCED" — incurs charges
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-user-pool"
  })
}

# Cognito-hosted domain for the sign-in UI (free)
resource "aws_cognito_user_pool_domain" "main" {
  for_each = var.features.cognito ? { this = {} } : {}

  domain       = "${var.name}-auth-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main["this"].id
}

# App client — public client (SPA/mobile), no client secret
resource "aws_cognito_user_pool_client" "main" {
  for_each = var.features.cognito ? { this = {} } : {}

  name         = "${var.name}-app-client"
  user_pool_id = aws_cognito_user_pool.main["this"].id

  generate_secret               = false # Public client
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}
