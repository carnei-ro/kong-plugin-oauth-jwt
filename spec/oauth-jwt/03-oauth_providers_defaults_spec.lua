require "spec.helpers"

local PLUGIN_NAME = "oauth-jwt"

local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

local function table_eq(table1, table2)
  local avoid_loops = {}
  local function recurse(t1, t2)
     -- compare value types
     if type(t1) ~= type(t2) then return false end
     -- Base case: compare simple values
     if type(t1) ~= "table" then return t1 == t2 end
     -- Now, on to tables.
     -- First, let's avoid looping forever.
     if avoid_loops[t1] then return avoid_loops[t1] == t2 end
     avoid_loops[t1] = t2
     -- Copy keys from t2
     local t2keys = {}
     local t2tablekeys = {}
     for k, _ in pairs(t2) do
        if type(k) == "table" then table.insert(t2tablekeys, k) end
        t2keys[k] = true
     end
     -- Let's iterate keys from t1
     for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if type(k1) == "table" then
           -- if key is a table, we need to find an equivalent one.
           local ok = false
           for i, tk in ipairs(t2tablekeys) do
              if table_eq(k1, tk) and recurse(v1, t2[tk]) then
                 table.remove(t2tablekeys, i)
                 t2keys[tk] = nil
                 ok = true
                 break
              end
           end
           if not ok then return false end
        else
           -- t1 has a key which t2 doesn't have, fail.
           if v2 == nil then return false end
           t2keys[k1] = nil
           if not recurse(v1, v2) then return false end
        end
     end
     -- if t2 has a key which t1 doesn't have, fail.
     if next(t2keys) then return false end
     return true
  end
  return recurse(table1, table2)
end

describe("[" .. PLUGIN_NAME .. "] oauth_providers_defaults", function()

  local oauth_providers_defaults = require("kong.plugins." .. PLUGIN_NAME .. ".oauth_providers_defaults")
  local default_conf = {
    ["on_invalid_jwt"] = "redirect_to_oauth_authorize_endpoint",
    ["state_secret"]   = "mystatesecret",
    ["jwt_keys"]       = {
      ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
    },
    ["oauth_client_id"]    = "myclientid",
    ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
    ["oauth_provider_authorize_endpoint_querystring_more"] = {},
  }

  describe("oauth providers defaults", function()

    it("custom - default", function()
      local conf = deepcopy(default_conf)
      conf["oauth_provider"] = "custom"
      conf["oauth_provider_authorize_endpoint"] = "https://my-gluu-server.com/oxauth/restv1/authorize"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], conf["oauth_provider_authorize_endpoint"])
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
      assert(table_eq(plugin_conf["oauth_scopes"], { "email", "profile", "openid" }))
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
    end)

    it("custom - with customized oauth scopes and querystring", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "custom"
      conf["oauth_provider_authorize_endpoint"] = "https://my-gluu-server.com/oxauth/restv1/authorize"
      conf["oauth_scopes"] = { "email", "profile", "openid", "kong_permissions" }
      conf["oauth_provider_authorize_endpoint_querystring_more"] = { ["foo"] = "bar" }

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], conf["oauth_provider_authorize_endpoint"])
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
      assert(table_eq(plugin_conf["oauth_scopes"], conf["oauth_scopes"]))
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
    end)

    it("facebook", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "facebook"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://www.facebook.com/v11.0/dialog/oauth")
      assert(table_eq(plugin_conf["oauth_scopes"], { "email", "public_profile" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

    it("github", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "github"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://github.com/login/oauth/authorize")
      assert(table_eq(plugin_conf["oauth_scopes"], { "user:read", "user:email" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], {['allow_signup'] = "false"}))
    end)

    it("gitlab", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "gitlab"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://gitlab.com/oauth/authorize")
      assert(table_eq(plugin_conf["oauth_scopes"], { "email", "profile", "openid" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

    it("google", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "google"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://accounts.google.com/o/oauth2/auth")
      assert(table_eq(plugin_conf["oauth_scopes"], { "email", "profile", "openid" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

    it("microsoft", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "microsoft"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://login.microsoftonline.com/common/oauth2/v2.0/authorize")
      assert(table_eq(plugin_conf["oauth_scopes"], { "User.Read" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

    it("yandex", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "yandex"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://oauth.yandex.com/authorize")
      assert(table_eq(plugin_conf["oauth_scopes"], { "login:email", "login:info", "login:avatar" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

    it("zoho", function()
      local conf = deepcopy(default_conf)

      conf["oauth_provider"] = "zoho"

      local plugin_conf = oauth_providers_defaults:set_defaults(conf)

      assert.is_truthy(plugin_conf)

      --print(require('pl.pretty').write(plugin_conf))
      assert.equal(plugin_conf["oauth_provider"], conf["oauth_provider"])
      assert.equal(plugin_conf["oauth_client_id"], conf["oauth_client_id"])
      assert.equal(plugin_conf["oauth_callback_url"], conf["oauth_callback_url"])
      assert.equal(plugin_conf["oauth_provider_authorize_endpoint"], "https://accounts.zoho.com/oauth/v2/auth")
      assert(table_eq(plugin_conf["oauth_scopes"], { "Aaaserver.profile.read" }))
      assert(table_eq(plugin_conf["oauth_provider_authorize_endpoint_querystring_more"], conf["oauth_provider_authorize_endpoint_querystring_more"]))
    end)

  end)

end)
