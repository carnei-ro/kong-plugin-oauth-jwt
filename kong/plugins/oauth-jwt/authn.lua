local plugin_name  = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local find_token   = require("kong.plugins." .. plugin_name .. ".find_token")
local ngx_now      = ngx.now
local ngx_time     = ngx.time
local jwt_decoder  = require "kong.plugins.jwt.jwt_parser"
local tostring     = tostring

local kong = kong

local _M = {}

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local function retrieve_jwt(conf, token)
  kong.log.debug(">>> Token was not in the cache")
  
  local jwt, err = jwt_decoder:new(token)
  if err then
    return nil, "Bad token; " .. tostring(err)
  end

  local kid = jwt.header.kid or 'default'
  kong.log.debug("Using Key_ID: " .. kid)
  if not conf['jwt_keys'][kid] then
    return nil, "Could not load public key: " .. kid
  end

  if not jwt:verify_signature(conf['jwt_keys'][kid]) then
    return nil, "Invalid signature"
  end

  local system_clock = ngx_now()
  if (conf.validate_jwt_claim_exp) and (jwt.claims.exp) and (system_clock > jwt.claims.exp) then
    return nil, "Token Expired"
  end

  if conf.override_ttl then
    kong.log.debug("Token valid. TTL: " .. tostring(conf.ttl))
    return jwt.claims
  else
    local token_ttl = jwt.claims.exp and (jwt.claims.exp - ( ngx_time() - 1 )) or 0.1
    kong.log.debug("Token valid. TTL: " .. tostring(token_ttl))
    return jwt.claims, nil, token_ttl
  end
end

function _M:authenticate(conf, cache)
  local token, err = find_token:retrieve_token(conf)
  if err then
    return false, err, nil
  end

  local token_type = type(token)
  if token_type ~= "string" then
    if token_type == "nil" then
      return false, "No JWT found", nil
    elseif token_type == "table" then
      return false, "Multiple tokens provided", nil
    else
      return false, "Unrecognizable token", nil
    end
  end

  local _,_,signature = token:match("([^.]*)%.([^.]*)%.([^.]*)")

  local claims, err
  if conf.use_cache then
    claims, err = cache:get(signature, { ttl = conf.ttl }, retrieve_jwt, conf, token)
  else
    claims, err = retrieve_jwt(conf, token)
  end
  if err then
    return false, err, nil
  end

  if conf["valid_jwt_claim_iss"] and (#conf["valid_jwt_claim_iss"] > 0) then
    if not has_value(conf.valid_jwt_claim_iss, claims.iss) then
      return nil, "Invalid iss", nil
    end
  end

  return true, nil, claims
end

return _M
