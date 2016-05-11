-- Composes redis and resty session together
local redis = require('redis')
local session = require('session')

local M = {}

function M.getSession()
  local sess = session.getSession()
  return sess
end

function M.startSession()
  local sess = M.getSession()
  local conn = redis.getRedisConnection()
  if conn  then
    redis.deleteValue(conn, sess.id)
  end
  sess:save()
  return sess
end

function M.saveAccessToken(sess, access_token)
  local conn = redis.getRedisConnection()
  if conn then
    return redis.setValue(conn, sess.id, access_token)
  end
  return nil
end

function M.saveUserInfo(sess, user_info)
  local conn = redis.getRedisConnection()
  if conn then
    return redis.setValue(conn, sess.id .. '_user_info', user_info)
  end
  return nil
end

function M.getAccessToken(sess)
  local conn = redis.getRedisConnection()
  if conn then
    return redis.getValue(conn, sess.id)
  end
  return nil
end

function M.getUserInfo(sess)
  local conn = redis.getRedisConnection()
  if conn then
    return redis.getValue(conn, sess.id .. '_user_info')
  end
  return nil
end

function M.removeSession(sess)
  local conn = redis.getRedisConnection()
  if conn then
    redis.deleteValue(conn, sess.id)
    redis.deleteValue(conn, sess.id .. '_user_info')
  end
  session.removeSession(sess)
  return true
end

return M
