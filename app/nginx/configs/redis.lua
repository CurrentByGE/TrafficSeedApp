-- Redis management module
local M = {}

local redis_credentials = nil

function readRedisInformation()
  local cjson = require('cjson')
  local vcap_services = cjson.decode(os.getenv('VCAP_SERVICES'))
  local redis_services_array = {}
  for k, v in pairs(vcap_services) do
    if string.match(k, 'redis') then
      redis_services_array = v
      break
    end
  end

  if #redis_services_array == 0 then
    print('Unable to find redis services in the VCAP_SERVICES environment variable')
  else
    local service_name = os.getenv('SESSION_STORE_SERVICE') or nil
    if service_name == nil then
      -- Use first index of the services array
      redis_credentials = redis_services_array[1].credentials
    else
      -- Find the service based on the name
      for service in redis_services_array do
        if service.name and service.name == service_name and service.credentials then
          redis_credentials = service.credentials
          break
        end
      end

      if not redis_credentials then
        -- Some stupid bastard put the wrong name as the environment variable then
        redis_credentials = redis_services_array[1].credentials
        print('Unable to find redis service named ' .. service_name .. ' this could mean that the SESSION_STORE_SERVICE value is incorrect')
      end
    end
  end

end

-- Acquire the latest redis information
readRedisInformation()

function M.getRedisConnection()
  if redis_credentials == nil then
    -- Early out if there is no redis connection information
    return nil
  end

  local redis = require('resty.redis')
  local red = redis:new()
  red:set_timeout(10000)

  local redis_host = redis_credentials.host
  local redis_port = redis_credentials.port
  local redis_password = redis_credentials.password

  local ok, err = red:connect(redis_host, redis_port)
  if not ok then
    print('Connecting to redis returned ' .. err)
    return nil
  end

  local res, err = red:auth(redis_password)
  if not res then
    print('Authenticating to redis returned ' .. err)
    return nil
  end

  return red
end

function M.setValue(red, name, val)
  return red:set(name, val)
end

function M.getValue(red, name)
  return red:get(name)
end

function M.deleteValue(red, name)
  red:del(name)
end

return M
