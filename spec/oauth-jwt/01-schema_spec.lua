local PLUGIN_NAME = "oauth-jwt"

-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

describe(PLUGIN_NAME .. ": (schema)", function()

  it("oauth custom - missing fields", function()
    local ok, err = validate({
        ["state_secret"]   = "mystatesecret",
        ["jwt_keys"]       = {
          ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
        },
        ["oauth_provider"]     = "custom",
        ["oauth_client_id"]    = "myclientid",
        ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
      })
    assert.is_truthy(err)
    assert.is_nil(ok)
    assert.equal('required field missing', err['config']['oauth_provider_authorize_endpoint'])
  end)

  it("oauth custom - ok", function()
    local ok, err = validate({
        ["state_secret"]   = "mystatesecret",
        ["jwt_keys"]       = {
          ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
        },
        ["oauth_provider"]     = "custom",
        ["oauth_client_id"]    = "myclientid",
        ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
        ["oauth_provider_authorize_endpoint"] = "http://my-gluu-server.com/oxauth/restv1/authorize",
      })
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)

  it("redirect_to_oauth_authorize_endpoint - missing fields", function()
    local ok, err = validate({
        ["on_invalid_jwt"] = "redirect_to_oauth_authorize_endpoint",
        ["jwt_keys"]       = {
          ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
        },
        ["oauth_client_id"]    = "myclientid",
        ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
      })
    assert.is_truthy(err)
    assert.is_nil(ok)
    -- print(require('pl.pretty').write(err))
    assert.equal('required field missing', err['config']['state_secret'])
  end)

  it("redirect_to_oauth_authorize_endpoint - ok", function()
    local ok, err = validate({
        ["on_invalid_jwt"] = "redirect_to_oauth_authorize_endpoint",
        ["state_secret"]   = "mystatesecret",
        ["jwt_keys"]       = {
          ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
        },
        ["oauth_client_id"]    = "myclientid",
        ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
      })
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)

end)
