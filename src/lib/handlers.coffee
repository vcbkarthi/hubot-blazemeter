request = require 'request'

collections = ['tests', 'collections', 'masters', 'sessions']

getRequestOptions = (apiKey, env, route, method = "GET") ->
  return {
    url: "#{env}/api/latest/#{route}"
    method: method
    headers: {
      'x-api-key': apiKey
    },
    json: true
  }

runRequest = (user, route, method, cb) ->
  options = getRequestOptions user.bmApiKey, user.bmEnv, route
  request.get options, cb

isValidUser = (user) ->
  unless user.bmEnv
    return "You have not set your blazemeter env"
  unless user.bmApiKey
    return "You have not set your blazemeter api-key"
  return true

getUserFromBrain = (robot, res) ->
  robot.brain.userForId res.message.user.id

exports.setRobot = (robot) ->
  @robot = robot

exports.handleReset = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  user.bmEnv = null
  user.bmApiKey = null
  @robot.brain.save()
  res.reply "Your env and api key are reset"

exports.handleSetEnv = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  value = res.match[1]
  user.bmEnv = value
  @robot.brain.save()
  res.reply "Got it, I updated your env to be #{value}"

exports.handleWhoami = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  validation = isValidUser user
  unless validation is true
    return res.reply validation

  route = "user"
  method = "GET"

  runRequest user, route, method, (err, response, body) ->
    return handleError(err, response, res) if err or response.statusCode >= 400

    display = body.result.displayName
    res.reply "Successfully checked in with #{user.bmEnv}. Using #{display}."

exports.handleSetApiKey = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  value = res.match[1]
  user.bmApiKey = value
  @robot.brain.save()
  res.reply "Got it, I updated your api key to be #{value}"

exports.handleGetEnv = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  unless user.bmEnv
    return res.reply "Your env is unset"

  res.reply "Your env is set to be #{user.bmEnv}"

exports.handleError = (err, response, robotResponse) ->
  if err
    return robotResponse.reply "Something went terribly wrong"

  if response.statusCode > 400
    return robotResponse.reply "Got #{response.statusCode}: #{response.statusMessage}"

  robotResponse.reply "I don't know what to do. Tried to take over the world"

exports.handleGetApiKey = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  unless user.bmApiKey
    return res.reply "Your api key is unset"

  res.reply "Your api key is set to be #{user.bmApiKey}"

exports.handleListRunning = (res) ->
  collection = res.match[1]
  unless collection in collections
    return res.reply "I'm not programmed to list #{collection}"

  user = getUserFromBrain @robot, res
  return unless user

  validation = isValidUser user
  unless validation is true
    return res.reply validation

  route = "web/active"
  method = "GET"

  runRequest user, route, method, (err, response, body) ->
    return handleError(err, response, res) if err or response.statusCode >= 400

    items = body?.result?[collection]
    if items?.length > 0
      res.reply "Current running #{collection}: #{items}"
    else
      res.reply "There are no running #{collection}"

exports.handleRunTest = (res) ->
  user = getUserFromBrain @robot, res
  return unless user

  test = res.match[1]

  validation = isValidUser user
  unless validation is true
    return res.reply validation

  route = "tests/#{test}/start"
  method = "POST"
  res.reply "Launching test #{test}. This might take a while..."

  runRequest user, route, method, (err, response, body) ->
    return handleError(err, response, res) if err or response.statusCode >= 400

    res.reply "Successfully launched the test with master #{body.result.id}"

exports.handleStopTest = (res) ->
  test = res.match[1]

  user = getUserFromBrain @robot, res
  return unless user

  validation = isValidUser user
  unless validation is true
    return res.reply validation

  route = "tests/#{test}/stop"
  method = "POST"
  res.reply "Stopping test #{test}. This might take a while..."

  runRequest user, route, method, (err, response, body) ->
    return handleError(err, response, res) if err or response.statusCode >= 400

    res.reply "Successfully sent the stop command"

exports.handleListCollections = (res) ->
  collection = res.match[1]
  unless collection in collections
    return res.reply "I'm not programmed to list #{collection}"

  user = getUserFromBrain @robot, res
  return unless user

  validation = isValidUser user
  unless validation is true
    return res.reply validation

  route = "#{collection}?limit=10"
  method = "GET"

  runRequest user, route, method, (err, response, body) ->
    return handleError(err, response, res) if err or response.statusCode >= 400
    items = body.result
    idList = ("#{item.id} - #{item.name}" for item in items)
    res.reply idList.join '\n'
