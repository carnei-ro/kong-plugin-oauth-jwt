local plugin_name  = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local typedefs     = require("kong.db.schema.typedefs")

return {
  name = plugin_name,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { on_invalid_jwt = {
            type = "string",
            default = "redirect_to_oauth_authorize_endpoint",
            required = true,
            one_of = { "redirect_to_oauth_authorize_endpoint", "return_unauthorized" },
          }, },
          { return_unauthorized_custom_response_headers = {
            type = "map",
            keys = {
              type = "string"
            },
            required = true,
            values = {
              type = "string",
              required = true,
            },
            default = {},
          }, },
          { state_algorithm = {
              type = "string",
              default = "sha256",
              required = true,
              one_of = { "sha256", "sha1", "md5" },
          }, },
          { state_secret = {
              type = "string",
              required = false,
          }, },
          { state_redirect_force_scheme = {
              type = "string",
              required = false,
              one_of = { "http", "https" },
          }, },
          { state_redirect_force_host = {
              type = "string",
              required = false,
          }, },
          { state_redirect_force_port = {
              type = "number",
              required = false,
          }, },
          { jwt_keys = {
            type = "map",
            keys = {
              type = "string"
            },
            required = true,
            values = {
              type = "string",
              required = true,
            },
          }, },
          { oauth_provider = {
              type = "string",
              default = "google",
              required = true,
              one_of = { "custom", "facebook", "github", "gitlab", "google", "microsoft", "yandex", "zoho" },
          }, },
          { oauth_provider_authorize_endpoint = {
              type = "string",
              required = false,
          }, },
          { oauth_provider_authorize_endpoint_querystring_more = {
            type = "map",
            keys = {
              type = "string"
            },
            required = true,
            values = {
              type = "string",
              required = true,
            },
            default = {},
          }, },
          { oauth_scopes = {
            type = "set",
            elements = { type = "string" },
            required = false
          } },
          { oauth_client_id = {
            type = "string",
            required = true,
          }, },
          { oauth_callback_url = {
            type = "string",
            required = true
          } },
          { find_token_at_query_params = {
            type = "set",
            default = { "oauth_jwt" },
            elements = { type = "string" },
            required = true
          } },
          { find_token_at_cookies = {
            type = "set",
            default = { "oauth_jwt" },
            elements = { type = "string" },
            required = true
          } },
          { find_token_at_headers = {
            type = "set",
            default = { "Authorization" },
            elements = { type = "string" },
            required = true
          } },
          { find_token_at_headers_bearer_prefix = {
            type = "boolean",
            default = true,
            required = true,
          } },
          { use_cache = {
            type = "boolean",
            default = true,
            required = true
          } },
          { override_ttl = {
            type = "boolean",
            default = false,
            required = true
          } },
          { ttl = {
            type = "number",
            default = 120,
            required = true
          } },
          { run_on_preflight = {
            type = "boolean",
            default = false,
            required = true
          } },
          { run_on_connection_upgrade = {
            type = "boolean",
            default = true,
            required = true
          } },
          { validate_jwt_claim_exp = {
            type = "boolean",
            default = true,
            required = true
          } },
          { valid_jwt_claim_iss = {
            type = "set",
            default = { "kong" },
            elements = { type = "string" },
            required = false
          } },
          { valid_jwt_claim_domains = {
            type = "set",
            elements = { type = "string" },
            required = false
          } },
          { valid_jwt_claim_sub_allowlist = {
            type = "set",
            elements = { type = "string" },
            required = false
          } },
          { valid_jwt_claim_sub_denylist = {
            type = "set",
            elements = { type = "string" },
            required = false
          } },
          { claims_to_headers = {
            type = "array",
            elements = {
              type = "record",
              required = true,
              fields = {
                { claim = {
                  type = "string",
                  required = true,
                }, },
                { header = {
                  type = "string",
                  required = true,
                }, },
              },
            },
            required = true,
            default = {
              { claim = "sub", header = "x-token-sub" }
            },
          } },
          { claims_to_validate = {
            type = "map",
            keys = { type = "string" },
            required = false,
            values = {
              type = "record",
              required = true,
              fields = {
                { values_are_regex = { type = "boolean", default = false }, },
                { accepted_values = { type = "array", elements = { type = "string" } }, },
              }
            },
          } },
          { use_cache_authz = {
            type = "boolean",
            default = true,
            required = true
          } },
          { authz_ttl = {
            type = "number",
            default = 1800,
            required = true
          } },
        },
      },
    },
  },
  entity_checks = {
    { conditional = {
      if_field = "config.on_invalid_jwt",
      if_match = { eq = "redirect_to_oauth_authorize_endpoint" },
      then_field = "config.state_secret",
      then_match = { required = true },
    }, },
    { conditional = {
      if_field = "config.oauth_provider",
      if_match = { eq = "custom" },
      then_field = "config.oauth_provider_authorize_endpoint",
      then_match = { required = true },
    }, },
  }
}
