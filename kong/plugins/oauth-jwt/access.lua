local plugin_name  = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local authn        = require("kong.plugins." .. plugin_name .. ".authn")
local authz        = require("kong.plugins." .. plugin_name .. ".authz")
local oauth        = require("kong.plugins." .. plugin_name .. ".oauth")
local mlcache      = require("resty.mlcache")
local kong         = kong
local cjson        = require("cjson.safe").new()

cjson.decode_array_with_array_mt(true)

local cache, err = mlcache.new(plugin_name, "oauth_jwt_shared_dict", {
  lru_size = 20000,  -- size of the L1 (Lua VM) cache
  ttl      = 120,    -- 120s ttl for hits
  neg_ttl  = 1,      -- 1s ttl for misses
})
if err then
  return error("failed to create the cache: " .. (err or "unknown"))
end

local _M = {}

function _M.execute(conf)
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end

  if not conf.run_on_connection_upgrade then
    local connection = kong.request.get_header('Connection')
    connection = connection and connection:lower() or nil
    if connection and (connection == 'upgrade') then
      return
    end
  end

  local ok, err, claims = authn:authenticate(conf, cache)
  if not ok then
    if conf.on_invalid_jwt == "return_unauthorized" then
      return kong.response.exit(401, {["err"] = err}, conf.return_unauthorized_custom_response_headers)
    end
    if conf.on_invalid_jwt == "redirect_to_oauth_authorize_endpoint" then
      oauth:redirect(conf)
    end
  end

  local authz, err = authz:authorize(conf, claims, cache)
  if (not authz) or err then
    kong.response.exit(403, err)
  end

  for _,cth in ipairs(conf.claims_to_headers) do
    local value = (type(claims[cth['claim']]) == "table") and cjson.encode(claims[cth['claim']]) or claims[cth['claim']]
    if (value == '{}') then value = nil end
    if value then
      kong.service.request.set_header(cth['header'], value)
    else
      kong.service.request.clear_header(cth['header'])
    end
  end
end

return _M
