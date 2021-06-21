local tostring     = tostring
local table_concat = table.concat
local type         = type
local toupper      = string.upper
local tostring     = tostring
local string_match = string.match
local cjson        = require("cjson.safe").new()
cjson.decode_array_with_array_mt(true)

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

local function authorize(conf, claims, key)
  local allow = true
  local err = nil

  -- Validate domains
  if conf["valid_jwt_claim_domains"] and (#conf["valid_jwt_claim_domains"] ~= 0) then
    kong.log.debug("Validating domains ...")
    if not has_value(conf.valid_jwt_claim_domains, claims.domain) then
      -- Allow if domain is not valid, but sub is listed on allowlist
      if conf["valid_jwt_claim_sub_allowlist"] and (#conf["valid_jwt_claim_sub_allowlist"] ~= 0) then
        kong.log.debug("Validating allow list ...")
        if not has_value(conf.valid_jwt_claim_sub_allowlist, claims.sub) then
          return nil, cjson.encode({ ["err"] = "Invalid domain", ["sub_allowlist"] = conf.valid_jwt_claim_sub_allowlist, ["sub"] = claims.sub, ["valid_domains"] = conf.valid_jwt_claim_domains, ["domain"] = claims.domain })
        end
      else
        return nil, cjson.encode({ ["err"] = "Invalid domain", ["valid_domains"] = conf.valid_jwt_claim_domains, ["domain"] = claims.domain })
      end
    end
  end

  if conf["valid_jwt_claim_sub_denylist"] and (#conf["valid_jwt_claim_sub_denylist"] ~= 0) then
    kong.log.debug("Validating deny list ...")
    if has_value(conf.valid_jwt_claim_sub_denylist, claims.sub) then
      return nil, cjson.encode({ ["err"] = "JWT sub is in denylist", ["invalid_subs"] = conf.valid_jwt_claim_sub_denylist, ["sub"] = claims.sub })
    end
  end

  if conf["claims_to_validate"] then
    kong.log.debug("Validating claims ...")
    allow = false
    err='{ "err": "Claim does not satisfy rules" }'
    for claim, configs in pairs(conf["claims_to_validate"]) do
      if claims[claim] then
        for _,accepted_value in ipairs(configs.accepted_values) do
          if type(claims[claim]) == 'table' then
            for _,claim_value in ipairs(claims[claim]) do
              if configs.values_are_regex then
                if string_match(claim_value, accepted_value) then
                  allow = true
                  err = nil
                end
              else
                if toupper(claim_value) == toupper(accepted_value) then
                  allow = true
                  err = nil
                end
              end
            end
          elseif type(claims[claim]) == 'string' then
            if configs.values_are_regex then
              if string_match(claims[claim], accepted_value) then
                allow = true
                err = nil
              end
            else
              if toupper(claims[claim]) == toupper(accepted_value) then
                allow = true
                err = nil
              end
            end
          elseif (type(claims[claim]) == 'number') or (type(claims[claim]) == 'boolean') then
            if tostring(claims[claim]) == accepted_value then
              allow = true
              err = nil
            end
          end
        end
      end
    end
  end

  return allow, err
end

function _M:authorize(conf, claims, cache)
  local route = kong.router.get_route()
  local key = table_concat({ route['id'], ':', (claims['iss'] or 'undefined'), ':', claims['sub'] })
  local authz, err
  if conf.use_cache_authz then
    authz, err = cache:get(key, { ttl = conf.authz_ttl }, authorize, conf, claims, key)
  else
    authz, err = authorize(conf, claims, key)
  end
  return authz, err
end

return _M
