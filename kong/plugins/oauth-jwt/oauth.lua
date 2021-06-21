local encode_args  = ngx.encode_args
local openssl_hmac = require("resty.openssl.hmac")
local b64_encode   = require("ngx.base64").encode_base64url
local cjson        = require("cjson.safe").new()
local table_concat = table.concat
cjson.decode_array_with_array_mt(true)

local _M = {}

local function generate_state(conf)
  local scheme = kong.request.get_scheme()
  scheme = conf.state_redirect_force_scheme and conf.state_redirect_force_scheme or scheme
  local host = kong.request.get_host()
  host = conf.state_redirect_force_host and conf.state_redirect_force_host or host
  local port = kong.request.get_port()
  port = conf.state_redirect_force_port and conf.state_redirect_force_port or port
  local path_with_query = kong.request.get_path_with_query()
  local string_to_sign = table_concat({'v0;', scheme, '://', host, ':', port, path_with_query})
  
  local signature, _ = openssl_hmac.new(conf.state_secret, conf.state_algorithm):final(string_to_sign)
  local signature_b64 = b64_encode(signature)

  local state = b64_encode(table_concat({'{"v":"v0","d":"', string_to_sign, '","s":"', signature_b64, '"}'}))
  return state
end

function _M:redirect(conf)
  local state = generate_state(conf)
  local querystring = conf.oauth_provider_authorize_endpoint_querystring_more
  querystring['client_id'] = conf.oauth_client_id
  querystring['scope'] = table_concat(conf.oauth_scopes, " ")
  querystring['response_type'] = "code"
  querystring['redirect_uri'] = conf.oauth_callback_url
  querystring['state'] = state
  return kong.response.exit(302, {}, {
    ['Location'] = table_concat({conf.oauth_provider_authorize_endpoint, "?", encode_args(querystring)})
  })
end

return _M
