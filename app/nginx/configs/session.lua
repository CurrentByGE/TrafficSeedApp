-- Session management module, atop resty_session
local resty_session = require('resty.session')

local M = {}

-- Get (or create) user's session
function M.getSession()
  local sess = resty_session.start()
  return sess
end

-- Removes the user's current session
function M.removeSession(session)
  session:destroy()
end

return M
