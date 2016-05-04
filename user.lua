-- Local module for user actions, such as logging in
local cjson = require('cjson')
local session_service = require('redis_session')
local M = {}

function M.getAuthenticationCode()
  local path = '/oauth/authorize'
  local uaa_uri = ngx.var.uaa_uri
  local redirect_uri_custom = ngx.var.custom_url
  if uaa_uri ~= nil then
    local query_string = ngx.encode_args({
      response_type = 'code',
      client_id = ngx.var.client_id,
      redirect_uri = 'https://' .. redirect_uri_custom .. '/oauth-callback',
      state = ngx.req.get_uri_args()['state'] or '/'
    })
    return ngx.redirect(uaa_uri .. path .. '?' .. query_string)
  else
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
  end
end

function exchangeToken(code)
  local state = ngx.req.get_uri_args().state or '/'
  local redirect_uri_custom = ngx.var.custom_url
  local response = ngx.location.capture(
      '/_internal/_access_token', {
          method = ngx.HTTP_POST,
          body = 'grant_type=authorization_code&code='..code..'&redirect_uri=https%3A%2F%2F'..redirect_uri_custom..'%2Foauth-callback&state='..state
      }
  )
  local json = cjson.decode(response.body)
  return json.access_token
end

function M.performAccessTokenHandshake()
  local query_parameters = ngx.req.get_uri_args()
  if query_parameters.code then
      local access_token = exchangeToken(query_parameters.code)
      if access_token ~= nil then
        local session = session_service.startSession()
        session_service.saveAccessToken(session, access_token)

        -- Also exchange the access token for current user information
        local user_info = requestCurrentUserInformation(access_token)
        session_service.saveUserInfo(session, cjson.encode(user_info))

        local state = ngx.req.get_uri_args().state or '/'
        return ngx.redirect(state)
      end
  end
end

function M.logout()

  -- Remove our session objects from redis as well
  local session = session_service.getSession()
  session_service.removeSession(session)
  local redirect_uri_custom = ngx.var.custom_url
  local uaa_uri = ngx.var.uaa_uri
  if uaa_uri ~= nil then
      local query_string = ngx.encode_args({
        redirect = 'https://' .. redirect_uri_custom,
      })
      return ngx.redirect(uaa_uri .. '/logout?' .. query_string)
  end
end

function requestCurrentUserInformation(token)
  local response = ngx.location.capture(
        '/_internal/_userinfo',
        {
            method = ngx.HTTP_POST,
            body = 'token='..token
        }
    )
    if response.status ~= ngx.HTTP_OK then
      return nil
    else
      local user_info_json = cjson.decode(response.body)
      -- Rewrite the user_info to expose only the fields we want
      return {
        name = user_info_json.user_name,
        email = user_info_json.email
      }
    end
end

function M.getUserInfo()
  local session = session_service.getSession()
  local user_info = session_service.getUserInfo(session)

  if not user_info or user_info == ngx.null then
    return nil
  else
    return user_info
  end
end

function M.getAccessToken()
  local session = session_service.getSession()
  local access_token = session_service.getAccessToken(session)
  return access_token
end

return M
