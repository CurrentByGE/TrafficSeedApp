--
-- Created by IntelliJ IDEA.
-- User: 212422863
-- Date: 11/2/15
-- Time: 9:16 AM
-- To change this template use File | Settings | File Templates.
--


-- Sets the access token for the currently proxied request

local user = require('user')

function set_access_token()
  local token = user.getAccessToken()
  if not token or token == ngx.null then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
  else
    ngx.var.user_token = "Bearer "..token
  end
end

set_access_token()
