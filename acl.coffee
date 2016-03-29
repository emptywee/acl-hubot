underscore = require "underscore"
util = require "util"
config = require "./acl.config.json"

getTimeStamp = ->
  date = new Date()
  timeStamp = date.getFullYear() + "/" + (date.getMonth() + 1) + "/" + date.getDate() + " " + date.getHours() + ":" +  date.getMinutes() + ":" + date.getSeconds()
  RE_findSingleDigits = /\b(\d)\b/g

  # Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )
  #timeStamp.replace /\s/g, ""

module.exports = (robot) ->
  # Map of listener ID to last time it was executed
  lastExecutedTime = {}
  # Map of listener ID to last time a reply was sent
  lastNotifiedTime = {}

  # Interval between mentioning that execution is rate limited
  if process.env.HUBOT_RATE_LIMIT_NOTIFY_PERIOD?
    notifyPeriodMs = parseInt(process.env.HUBOT_RATE_LIMIT_NOTIFY_PERIOD)*1000
  else
    notifyPeriodMs = 10*1000 # default: 10s

  #robot.respond /debug rate limits/, {rateLimits:{minPeriodMs:0}}, (response) ->
  #  response.reply('lastExecutedTime: ' + JSON.stringify(lastExecutedTime))
  #  response.reply('lastNotifiedTime: ' + JSON.stringify(lastNotifiedTime))

  robot.listenerMiddleware (context, next, done) ->
    # Retrieve the listener id. If one hasn't been registered, fallback
    # to using the regex to uniquely identify the listener (even though
    # it is dirty).
    cmd = context.response.message.text
    chatUser = context.response.message.user.name
    chatRoom = context.response.message.user.room
    console.log getTimeStamp() + " robot.listenerMiddleware called with message: \'" + cmd + "\' by \'" + chatUser + "\' at room \'" + chatRoom + "\'"
#    console.log getTimeStamp() + " user: " + chatUser 
#    console.log getTimeStamp() + " room: " + chatRoom

    # strip bot name
    cmd = cmd.replace(/^\s*[@]?(?:rnimubot[:,]?|![:,]?)\s*/, "")
    # console.log getTimeStamp() + " stripped command: " + cmd

    for restrictedCommand, groups of config.commands.restricted
        # console.log getTimeStamp() + " " + restrictedCommand + "=" + groups
        regex = new RegExp("^" + restrictedCommand)
        if cmd.match(regex)
          # console.log getTimeStamp() + " command " + cmd + " is restricted to " + groups
          # check if user is in the group
          for group in groups
            if config.groups.hasOwnProperty(group)
             # console.log getTimeStamp() + " found group " + group + " in config"
              found = false
              for user in config.groups[group]
              #  console.log getTimeStamp() + " found user " + user + " in group " + group
                if user == chatUser
                #  console.log getTimeStamp() + " user " + chatUser + " is allowed to exec this command "
                  found = true
                  break
              if not found
                # respond with access denied
                console.log getTimeStamp() + " Access denied for \'" + chatUser + "\' to execute command \'" + cmd + "\'"
                context.response.reply "Access denied to execute command: \'" + cmd +"\'"
                return
              else
                # respond with access granted and proceed
                console.log getTimeStamp() + " Access granted for \'" + chatUser + "\' to execute command \'" + cmd + "\'"
                context.response.reply "Access granted to execute command: \'" + cmd + "\'"
                next () ->
                  done()
                return
          break

    next () ->
         done()
