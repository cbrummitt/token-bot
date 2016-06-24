# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   KARMA_ALLOW_SELF
#
# Commands:
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   hubot karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#   hubot karma empty <thing> - empty a thing's karma
#   hubot karma best - show the top 5
#   hubot karma worst - show the bottom 5
#
# Author:
#   stuartf

class Karma

  constructor: (@robot) ->
    @cache = {}
    @cacheTokens = {}

    maxTokensPerUser = 5

    # list of responses to show when someone gets karma
    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]

    # list of responses to show when someone loses karma
    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]


    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma

  # remove a key-item pair from the @cache
  kill: (thing) ->
    delete @cache[thing]
    @robot.brain.data.karma = @cache

  increment: (thing) ->
    # check whether @cache[thing] is a variable that exists and if not set it to 0
    @cache[thing] ?= 0
    # increment @cache[thing]
    @cache[thing] += 1
    @robot.brain.data.karma = @cache

  decrement: (thing) ->
    # if the variable cache[thing] does not exist, then set it equal to 0
    @cache[thing] ?= 0
    # decrement @cache[thing]
    @cache[thing] -= 1
    @robot.brain.data.karma = @cache


##### begin Charlie's code #######
  addToken: (sender, recipient) -> 
    # check whether @cacheTokens[sender] exists and if not set it to []
    @cacheTokens[sender] ?= []

    # if the sender has not already given out more that `maxTokensPerUser` tokens, then add recepient to @cacheTokens[sender]'s list
    if @cacheTokens[sender].length < maxTokensPerUser:
      @cacheTokens[sender] push recipient



##### end Charlie's code #######

  # return a uniformly random response for incrementing someone's karma
  incrementResponse: ->
     @increment_responses[Math.floor(Math.random() * @increment_responses.length)]

  decrementResponse: ->
     @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  selfDeniedResponses: (name) ->
    @self_denied_responses = [
      "Hey everyone! #{name} is a narcissist!",
      "I might just allow that next time, but no.",
      "I can't do that #{name}."
    ]

  get: (thing) ->
    k = if @cache[thing] then @cache[thing] else 0
    return k

  sort: ->
    s = []
    for key, val of @cache
      s.push({ name: key, karma: val })
    s.sort (a, b) -> b.karma - a.karma

  top: (n = 5) ->
    sorted = @sort()
    sorted.slice(0, n)

  bottom: (n = 5) ->
    sorted = @sort()
    sorted.slice(-n).reverse()

module.exports = (robot) ->
  robot.logger.warning "karma.coffee has merged with plusplus.coffee and moved from hubot-scripts to its own package. Remove it from your hubot-scripts.json and see https://github.com/ajacksified/hubot-plusplus for upgrade instructions"

  karma = new Karma robot
  allow_self = process.env.KARMA_ALLOW_SELF or "true"

  # Charlie's "given token" message
  robot.hear /give token (@\S+)+(\s|$)/, (msg) ->

    recipient = msg.match[1].toLowerCase()

    # if the sender has not given out any tokens yet, or 
    # if the sender has not already given out more that `maxTokensPerUser` tokens, 
    # then add recepient to @cacheTokens[sender]'s list
    if not(@cacheTokens[sender]?) or @cacheTokens[sender].length < maxTokensPerUser:
      @cacheTokens[sender] ?= [] # if @cacheTokens[sender] doesn't exist then set it equal to []
      @cacheTokens[sender] push recipient # add recipient to the list
      msg.send "#{msg.message.user.name} gave one token to #{recipient}"
      msg.send "#{msg.message.user.name} has given tokens to #{@cacheTokens[sender]}"


  robot.hear /(\S+[^+:\s])[: ]*\+\+(\s|$)/, (msg) ->

    # `msg.match(regex)` checks whether msg matches the regular expression regex. I'm not sure what `msg.match[1]` does. 
    # Does the [1] refer to the first capturing group in the regular expression /(\S+[^+:\s])[: ]*\+\+(\s|$)/? 
    # Or does [1] refer to the first argument of this function?
    subject = msg.match[1].toLowerCase()
    if allow_self is true or msg.message.user.name.toLowerCase() != subject
      karma.increment subject
      msg.send "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"
    else
      msg.send msg.random karma.selfDeniedResponses(msg.message.user.name)

  robot.hear /(\S+[^-:\s])[: ]*--(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    if allow_self is true or msg.message.user.name.toLowerCase() != subject
      karma.decrement subject
      msg.send "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"
    else
      msg.send msg.random karma.selfDeniedResponses(msg.message.user.name)

  robot.respond /karma empty ?(\S+[^-\s])$/i, (msg) ->
    subject = msg.match[1].toLowerCase()
    if allow_self is true or msg.message.user.name.toLowerCase() != subject
      karma.kill subject
      msg.send "#{subject} has had its karma scattered to the winds."
    else
      msg.send msg.random karma.selfDeniedResponses(msg.message.user.name)

  robot.respond /karma( best)?$/i, (msg) ->
    verbiage = ["The Best"]
    for item, rank in karma.top()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma worst$/i, (msg) ->
    verbiage = ["The Worst"]
    for item, rank in karma.bottom()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma (\S+[^-\s])$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match != "best" && match != "worst"
      msg.send "\"#{match}\" has #{karma.get(match)} karma."