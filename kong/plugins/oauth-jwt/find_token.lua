local kong = kong
local type = type
local ipairs = ipairs
local re_gmatch = ngx.re.gmatch

local _M = {}

function _M:retrieve_token(conf)
  local args = kong.request.get_query()
  for _, v in ipairs(conf.find_token_at_query_params) do
    if args[v] then
      return args[v]
    end
  end

  local var = ngx.var
  for _, v in ipairs(conf.find_token_at_cookies) do
    local cookie = var["cookie_" .. v]
    if cookie and cookie ~= "" then
      return cookie
    end
  end

  local request_headers = kong.request.get_headers()
  for _, v in ipairs(conf.find_token_at_headers) do
    local token_header = request_headers[v]
    if token_header then
      if type(token_header) == "table" then
        token_header = token_header[1]
      end

      if not conf.find_token_at_headers_bearer_prefix then
        return token_header
      end

      local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
      if not iterator then
        kong.log.err(iter_err)
        break
      end

      local m, err = iterator()
      if err then
        kong.log.err(err)
        break
      end

      if m and #m > 0 then
        return m[1]
      end
    end
  end
end

return _M
