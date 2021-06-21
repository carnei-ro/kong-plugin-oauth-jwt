local helpers = require "spec.helpers"
local table_concat = table.concat
local encode_args  = ngx.encode_args

local PLUGIN_NAME = "oauth-jwt"

local default_configs = {
  ["on_invalid_jwt"] = "redirect_to_oauth_authorize_endpoint",
  ["state_secret"]   = "mystatesecret",
  ["jwt_keys"]       = {
    ["privkey1"] = "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2\nQX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==\n-----END PUBLIC KEY-----",
  },
  ["oauth_provider"]     = "custom",
  ["oauth_client_id"]    = "myclientid",
  ["oauth_callback_url"] = "http://localhost:9000/auth/callback",
  ["oauth_scopes"]       = { "email", "profile", "openid" },
  ["oauth_provider_authorize_endpoint"] = "https://my-gluu-server.com/oxauth/restv1/authorize",
}

local google_jwt = "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0.eyJpYXQiOjE2MjQyODUxODUsImlzcyI6ImtvbmciLCJuYW1lIjoiTGVhbmRybyBDYXJuZWlybyIsImRvbWFpbiI6Imdvb2dsZS5jb20iLCJwcm92aWRlciI6Imdvb2dsZSIsInVzZXIiOiJsZWFuZHJvIiwiZ2l2ZW5fbmFtZSI6IkxlYW5kcm8iLCJzdWIiOiJsZWFuZHJvQGdvb2dsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmFtaWx5X25hbWUiOiJDYXJuZWlybyIsImV4cCI6OTkyNDM3MTU4NX0.O0TcU7hxW9drqgFwJoJr1BRfa9vTtuipVlbDsR2Xc5uXY8lTuky8H65ckksh1ykwYqEuOuqvO-PEIJcuxkS0Cw"
local unknown_kid_jwt = "eyJraWQiOiJrZXkyIiwiYWxnIjoiUlMyNTYiLCJ0eXAiOiJKV1QifQ.eyJpYXQiOjE2MjQyODUxODUsImlzcyI6ImtvbmciLCJuYW1lIjoiTGVhbmRybyBDYXJuZWlybyIsImRvbWFpbiI6ImNhcm5laS5ybyIsInJvbGVzIjpbIkFkbWluIl0sInByb3ZpZGVyIjoiZ2x1dSIsInVzZXIiOiJsZWFuZHJvIiwiZ2l2ZW5fbmFtZSI6IkxlYW5kcm8iLCJzdWIiOiJsZWFuZHJvQGNhcm5laS5ybyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmYW1pbHlfbmFtZSI6IkNhcm5laXJvIiwiZXhwIjo5OTI0Mjg1MTg2fQ.XgRnrul1EmmcSaBx6dpgMTx_0zPrQo3C5JoVR9HX34eIwsT3otc21NPtvHfXfHFWsCyEC0eQNAdeZKS3fkp61w"
local invalid_issuer_jwt = "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0.eyJpYXQiOjE2MjQyODUxODUsImlzcyI6ImNhcm5laXJvIiwibmFtZSI6IkxlYW5kcm8gQ2FybmVpcm8iLCJkb21haW4iOiJjYXJuZWkucm8iLCJyb2xlcyI6WyJBZG1pbiJdLCJwcm92aWRlciI6ImdsdXUiLCJ1c2VyIjoibGVhbmRybyIsImdpdmVuX25hbWUiOiJMZWFuZHJvIiwic3ViIjoibGVhbmRyb0BjYXJuZWkucm8iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmFtaWx5X25hbWUiOiJDYXJuZWlybyIsImV4cCI6OTkyNDI4NTE4Nn0.pXZQ6N0JfY2ZpPGS0gBw1Sz9F-9cdAUX3zg__6nqbCDkX22bX2DC_qFe0i3mlNN4hMb2VxnKIz8D0p8MuGw2GA"
local expired_jwt = "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0.eyJpYXQiOjE2MjQyODUxODUsImlzcyI6ImtvbmciLCJuYW1lIjoiTGVhbmRybyBDYXJuZWlybyIsImRvbWFpbiI6ImNhcm5laS5ybyIsInJvbGVzIjpbIkFkbWluIl0sInByb3ZpZGVyIjoiZ2x1dSIsInVzZXIiOiJsZWFuZHJvIiwiZ2l2ZW5fbmFtZSI6IkxlYW5kcm8iLCJzdWIiOiJsZWFuZHJvQGNhcm5laS5ybyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmYW1pbHlfbmFtZSI6IkNhcm5laXJvIiwiZXhwIjoxNjI0Mjg1MTg2fQ.b_nfeQAid70AFc2f0gYYHWlJPy4XDeDXt9OL1LXshwPVownixLFjHGB8ten-Fkq7-C2Ya3Lm0sVGGjHzOn9Tiw"
local valid_jwt = "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0.eyJpYXQiOjE2MjQyODUxODUsImlzcyI6ImtvbmciLCJuYW1lIjoiTGVhbmRybyBDYXJuZWlybyIsImRvbWFpbiI6ImNhcm5laS5ybyIsInJvbGVzIjpbIkFkbWluIl0sInByb3ZpZGVyIjoiZ2x1dSIsInVzZXIiOiJsZWFuZHJvIiwiZ2l2ZW5fbmFtZSI6IkxlYW5kcm8iLCJzdWIiOiJsZWFuZHJvQGNhcm5laS5ybyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmYW1pbHlfbmFtZSI6IkNhcm5laXJvIiwiZXhwIjo5OTI0MzcxNTg1fQ.a4VZWnE8JaXiLCzpsNf_B-uRlMMfGMe61TPdVGUyFu1ihat5fNYspabYyxiT-zbT3PJuFckKHSQKKMJy-YCgwQ"
-- local valid_jwt_claims = {
--   ["iat"] = 1624285185,
--   ["iss"] = "kong",
--   ["name"] = "Leandro Carneiro",
--   ["domain"] = "carnei.ro",
--   ["roles"] = { "Admin" },
--   ["provider"] = "gluu",
--   ["user"] = "leandro",
--   ["given_name"] = "Leandro",
--   ["sub"] = "leandro@carnei.ro",
--   ["email_verified"] = true,
--   ["family_name"] = "Carneiro",
--   ["exp"] = 9924371585
-- }

for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      local route0 = bp.routes:insert({
        hosts = { "redirect-to-oauth-authorize-endpoint-custom-state.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route0.id },
        config = kong.table.merge(default_configs, {
          state_redirect_force_scheme = "https",
          state_redirect_force_host = "bar.foo",
          state_redirect_force_port = 443,
        }),
      }

      local route1 = bp.routes:insert({
        hosts = { "redirect-to-oauth-authorize-endpoint.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = default_configs,
      }

      local route2 = bp.routes:insert({
        hosts = { "return-unauthorized.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = kong.table.merge(default_configs, {
          on_invalid_jwt = 'return_unauthorized',
          return_unauthorized_custom_response_headers = {
            ["WWW-Authenticate"] = 'error="invalid_token"'
          },
        }),
      }

      local route3 = bp.routes:insert({
        hosts = { "token-is-valid-custom-header.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route3.id },
        config = kong.table.merge(default_configs, {
          find_token_at_headers = {'x-service-token'},
          find_token_at_headers_bearer_prefix = false,
          validate_jwt_claim_exp = false,
        }),
      }

      local route4 = bp.routes:insert({
        hosts = { "authz1-require-admin.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route4.id },
        config = kong.table.merge(default_configs, {
          claims_to_validate = {
            roles = { values_are_regex = false, accepted_values = { "Admin" } }
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }

      local route5 = bp.routes:insert({
        hosts = { "authz2-require-root.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route5.id },
        config = kong.table.merge(default_configs, {
          claims_to_validate = {
            roles = { values_are_regex = false, accepted_values = { "root" } }
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }

      local route6 = bp.routes:insert({
        hosts = { "authz3-domain-carnei.ro.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route6.id },
        config = kong.table.merge(default_configs, {
          valid_jwt_claim_domains = {
            "carnei.ro"
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }

      local route7 = bp.routes:insert({
        hosts = { "authz4-domain-carnei.ro-with-sub-allowlist.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route7.id },
        config = kong.table.merge(default_configs, {
          valid_jwt_claim_sub_allowlist = {
            "leandro@google.com"
          },
          valid_jwt_claim_domains = {
            "carnei.ro"
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }

      local route8 = bp.routes:insert({
        hosts = { "authz5-domain-carnei.ro-with-sub-allowlist-and-require-admin.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route8.id },
        config = kong.table.merge(default_configs, {
          valid_jwt_claim_sub_allowlist = {
            "leandro@google.com"
          },
          valid_jwt_claim_domains = {
            "carnei.ro"
          },
          claims_to_validate = {
            roles = { values_are_regex = false, accepted_values = { "Admin" } }
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }

      local route9 = bp.routes:insert({
        hosts = { "authz6-domain-carnei.ro-or-google.com-with-sub-denylist.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route9.id },
        config = kong.table.merge(default_configs, {
          valid_jwt_claim_sub_denylist = {
            "leandro@google.com"
          },
          valid_jwt_claim_domains = {
            "carnei.ro",
            "google.com"
          },
          claims_to_headers = { 
            { claim = "sub", header = "x-token-sub" },
            { claim = "roles", header = "x-token-roles" }
          },
        }),
      }


      -- start kong
      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
        nginx_http_lua_shared_dict = "oauth_jwt_shared_dict 32m"
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)


    describe("response", function()
      it("redirect to oauth authorize endpoint - custom redirect state", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "redirect-to-oauth-authorize-endpoint-custom-state.foo"
          }
        })
        assert.response(r).has.status(302)
        -- print(require('pl.pretty').write(r.headers))

        local header_location = assert.response(r).has.header("Location")
        local location_regex = table_concat({
          "^",
          default_configs.oauth_provider_authorize_endpoint,
          "?",
          "response_type=code&client_id=",
          default_configs.oauth_client_id,
          "&state=",
          -- by using this static string, we are already ensuring the function "generate state" is working properly
          "eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9iYXIuZm9vOjQ0My9mb28vYmFyP2Jhej1xdXgmcXV6PWNvcmdlIiwicyI6Im8xeXFyM2Y1WUpjRnp3Z2tMai1kaTg2eVNFT3FCYmplT3h3NDBlaWNCejAifQ",
          "&",
          encode_args({scope = table_concat(default_configs.oauth_scopes, " ")}),
          "&",
          encode_args({redirect_uri = default_configs.oauth_callback_url}),
          "$"
        }):gsub("%%", "%%%%"):gsub("-", "%%-"):gsub("%?", "%%?"):gsub("%&", "%%&")
        assert.matches(location_regex, header_location)
      end)

      it("redirect to oauth authorize endpoint", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "redirect-to-oauth-authorize-endpoint.foo"
          }
        })
        assert.response(r).has.status(302)
        -- print(require('pl.pretty').write(r.headers))

        local header_location = assert.response(r).has.header("Location")
        local location_regex = table_concat({
          "^",
          default_configs.oauth_provider_authorize_endpoint,
          "?",
          "response_type=code&client_id=",
          default_configs.oauth_client_id,
          "&state=",
          -- by using this static string, we are already ensuring the function "generate state" is working properly
          "eyJ2IjoidjAiLCJkIjoidjA7aHR0cDovL3JlZGlyZWN0LXRvLW9hdXRoLWF1dGhvcml6ZS1lbmRwb2ludC5mb286OTAwMC9mb28vYmFyP2Jhej1xdXgmcXV6PWNvcmdlIiwicyI6IkQ5cjFDZjZSVzhlMjAzY0FadV93R0pkZE9nQ2FrVzZudnFWUFBpblljTUEifQ",
          "&",
          encode_args({scope = table_concat(default_configs.oauth_scopes, " ")}),
          "&",
          encode_args({redirect_uri = default_configs.oauth_callback_url}),
          "$"
        }):gsub("%%", "%%%%"):gsub("-", "%%-"):gsub("%?", "%%?"):gsub("%&", "%%&")
        assert.matches(location_regex, header_location)
      end)

      it("return unauthorized", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo"
          }
        })
        assert.response(r).has.status(401)
        assert.is_nil(r.headers["Location"])
        assert.equal(r.headers["WWW-Authenticate"], 'error="invalid_token"')
      end)
    end)

    describe("authenticate", function()
      it("token in header authorization is expired", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            authorization = "Bearer " .. expired_jwt,
          }
        })
        assert.response(r).has.status(401)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Token Expired")
      end)

      it("token is expired but not validating", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "token-is-valid-custom-header.foo",
            ['x-service-token'] = valid_jwt,
            authorization = "Bearer " .. expired_jwt,
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
      end)

      it("token invalid issuer", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            authorization = "Bearer " .. invalid_issuer_jwt,
          }
        })
        assert.response(r).has.status(401)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Invalid iss")
      end)

      it("token in header authorization is invalid kid", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            authorization = "Bearer " .. unknown_kid_jwt,
          }
        })
        assert.response(r).has.status(401)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Could not load public key: key2")
      end)

      it("token in header authorization is invalid signature", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            authorization = "Bearer " .. valid_jwt:gsub("gwQ$", "foo"),
          }
        })
        assert.response(r).has.status(401)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Invalid signature")
      end)

      it("token in header authorization is valid", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            authorization = "Bearer " .. valid_jwt,
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
      end)

      it("token in querystring is valid", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge&oauth_jwt=" .. valid_jwt, {
          headers = {
            host = "return-unauthorized.foo",
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
      end)

      it("token in cookies is valid", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "return-unauthorized.foo",
            cookie = "oauth_jwt=" .. valid_jwt,
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
      end)

      it("token in header x-service-token is valid", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "token-is-valid-custom-header.foo",
            ['x-service-token'] = valid_jwt,
            ['x-token-sub'] = "spoofing@email.com",
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
      end)
    end)

    describe("authorizate", function()
      it("token admin", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz1-require-admin.foo",
            authorization = "Bearer " .. valid_jwt
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
        assert.equal(body['headers']['x-token-roles'], '["Admin"]')
      end)

      it("token root", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz2-require-root.foo",
            authorization = "Bearer " .. valid_jwt
          }
        })
        assert.response(r).has.status(403)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Claim does not satisfy rules")
      end)

      it("token invalid domain - ok", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz3-domain-carnei.ro.foo",
            authorization = "Bearer " .. valid_jwt
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
        assert.equal(body['headers']['x-token-roles'], '["Admin"]')
      end)

      it("token invalid domain - forbidden", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz3-domain-carnei.ro.foo",
            authorization = "Bearer " .. google_jwt
          }
        })
        assert.response(r).has.status(403)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Invalid domain")
      end)

      it("token valid domain but sub allow list", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz4-domain-carnei.ro-with-sub-allowlist.foo",
            authorization = "Bearer " .. google_jwt
          }
        })
        --print(require('pl.pretty').write(r))
        local body = assert.response(r).has.jsonbody()
        assert.response(r).has.status(404)       
        assert.equal(body['headers']['x-token-sub'], "leandro@google.com")
      end)

      it("token valid domain but sub allow list, although not admin", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz5-domain-carnei.ro-with-sub-allowlist-and-require-admin.foo",
            authorization = "Bearer " .. google_jwt
          }
        })
        assert.response(r).has.status(403)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "Claim does not satisfy rules")
      end)

      it("token valid domain but sub is in denylist", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz6-domain-carnei.ro-or-google.com-with-sub-denylist.foo",
            authorization = "Bearer " .. google_jwt
          }
        })
        assert.response(r).has.status(403)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['err'], "JWT sub is in denylist")
      end)

      it("token valid domain and sub is not in denylist", function()
        local r = client:get("/foo/bar?baz=qux&quz=corge", {
          headers = {
            host = "authz6-domain-carnei.ro-or-google.com-with-sub-denylist.foo",
            authorization = "Bearer " .. valid_jwt
          }
        })
        assert.response(r).has.status(404)
        local body = assert.response(r).has.jsonbody()
        assert.equal(body['headers']['x-token-sub'], "leandro@carnei.ro")
        assert.equal(body['headers']['x-token-roles'], '["Admin"]')
      end)
    end)

  end)
end
