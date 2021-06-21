local _M = {}

local function custom(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "email", "profile", "openid" }
  return config
end

local function facebook(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "email", "public_profile" }
  config.oauth_provider_authorize_endpoint = "https://www.facebook.com/v11.0/dialog/oauth"
  return config
end

local function github(config)
  config.oauth_provider_authorize_endpoint_querystring_more['allow_signup'] = 
    config.oauth_provider_authorize_endpoint_querystring_more['allow_signup'] and
    config.oauth_provider_authorize_endpoint_querystring_more['allow_signup'] or
    "false"
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "user:read", "user:email" }
  config.oauth_provider_authorize_endpoint = "https://github.com/login/oauth/authorize"
  return config
end

local function gitlab(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "email", "profile", "openid" }
  config.oauth_provider_authorize_endpoint = "https://gitlab.com/oauth/authorize"
  return config
end

local function google(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "email", "profile", "openid" }
  config.oauth_provider_authorize_endpoint = "https://accounts.google.com/o/oauth2/auth"
  return config
end

local function microsoft(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "User.Read" }
  config.oauth_provider_authorize_endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
  return config
end

local function yandex(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "login:email", "login:info", "login:avatar" }
  config.oauth_provider_authorize_endpoint = "https://oauth.yandex.com/authorize"
  return config
end

local function zoho(config)
  config.oauth_scopes = config.oauth_scopes and config.oauth_scopes or { "Aaaserver.profile.read" }
  config.oauth_provider_authorize_endpoint = "https://accounts.zoho.com/oauth/v2/auth"
  return config
end

local defaults = {
  ["custom"]    = custom,
  ["facebook"]  = facebook,
  ["github"]    = github,
  ["gitlab"]    = gitlab,
  ["google"]    = google,
  ["microsoft"] = microsoft,
  ["yandex"]    = yandex,
  ["zoho"]      = zoho,
}

function _M:set_defaults(config)
  if defaults[config.oauth_provider] == nil then
    return config
  end
  return defaults[config.oauth_provider](config)
end

return _M
