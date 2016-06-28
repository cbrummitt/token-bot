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


# ##### begin Charlie's code #######

class KarmaNetwork
  #### Constructor ####
  constructor: (@robot) -> 
    # a dictionary of which tokens have been given to whom
    @tokens_given = {}
    
    # each user can give at most this many tokens to others
    # TODO: make this an environment variable? See `allow_self = process.env.KARMA_ALLOW_SELF or "true"` in the karma bot
    @max_tokens_per_user = 5 

    # variable that determines whether tokens can be given right now
    # TDOO: write a method that will turn this off and display a message in #general telling everyone that tokens can no longer be given?
    @tokens_can_be_given = true
    @tokens_can_be_revoked = true

    # list of responses to display when someone receives or gives a token
    @receive_token_responses = ["received a token!", "was thanked with a token!"]
    @revoke_token_responses = ["lost a token :(", "had a token revoked"]

    # if the brain was already on, then set the cache to the dictionary @robot.brain.data.tokens_given
    # the fat arrow `=>` binds the current value of `this` (i.e., `@`) on the spot
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.tokens_given
        @tokens_given = @robot.brain.data.tokens_given


  #### Methods ####

  give_token: (sender, recipient) -> 
    # check whether tokens can be given. 
    # TODO: do this in the method that listens for the command? If @tokens_can_be_given is false, then we should display the message `Tokens can no longer be given.`
    if @tokens_can_be_given

      # check whether @cacheTokens[sender] exists and if not set it to []
      @tokens_given[sender] ?= []

      # if the sender has not already given out more that `@max_tokens_per_user` tokens, then add recepient to @cacheTokens[sender]'s list.
      # note that this allows someone to send multiple tokens to the same user
      @tokens_given[sender].push recipient if @tokens_given[sender].length < @max_tokens_per_user
      @robot.brain.data.tokens_given = @tokens_given

      # TODO: if @tokens_given[sender].length >= @max_tokens_per_user, we want to send a message to the user saying that they've already given out all their tokens
      # Send a message like the following:
      #     You do not have any more tokens to give out. Type "token status" to find out to whom you have given your tokens, and type "token revoke @username" to revoke a token from @username.

      # TODO: send a message that announces that a token was given using a command like
      #       msg.send "#{subject} #{karma.receive_token_response()} (Karma: #{karma.get(subject)})"
      # in the robot.hear /(\S+[^+:\s])[: ]*\+\+(\s|$)/, (msg) function (or the equivalent that we write)

  revoke_token: (sender, recipient) ->
    # remove recipient from @tokens_given[sender] 
    # note that if the sender has given >1 token to recipient, this will remove just one of those tokens from the recipient.
    if @tokens_can_be_revoked
      index = @tokens_given[sender].indexOf sender
      @tokens_given.splice index, 1 if index isnt -1

    # TODO: send a message using 
    #       msg.send "#{subject} #{karma.revoke_token_response()} (Karma: #{karma.get(subject)})"
    # in the robot.hear /(\S+[^+:\s])[: ]*\+\+(\s|$)/, (msg) function
  # return a uniformly random response for giving a token to someone someone's karma

  receive_token_response: ->
    @receive_token_responses[Math.floor(Math.random() * @receive_token_responses.length)]

  revoke_token_response: ->
    @revoke_token_responses[Math.floor(Math.random() * @revoke_token_responses.length)]

  selfDeniedResponses: (name) ->
    @self_denied_responses = [
      "Sorry #{name}. Tokens cannot be given to oneself.",
      "I can't do that #{name}.",
      "Tokens can only be given to other people."
    ]

  status: (name) -> 
    # return the number of tokens given and to whom

    # displays how many of your tokens you still have, and how many you have given to other people, 
    # and how many tokens you have received from other users

    # Example:
    # You have 2 of your own tokens in your pocket. 
    # You have given tokens to the following people: 
    # @user_4 (1 token)
    # @user_8 (2 tokens) 
    # You have received 2 tokens from others: 
    # @user_4 (1 token)
    # @user_5 (1 token)
    

    # in the code that listens for this command, we could display this if 
    #       msg.message.user.name.toLowerCase() == subject 
    # where subject = subject = msg.match[1].toLowerCase()
    # Way to go! Get more tokens by contributing to others' ideas. Each token from a winning business proposal earns prize money.


module.exports = (robot) ->
  tokenBot = new KarmaNetwork robot

  # environment variables
  allow_self = process.env.KARMA_ALLOW_SELF or "true"

###### end Charlie's code #######




class Karma

  constructor: (@robot) ->
    @cache = {}

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

  # # Charlie's "given token" message
  # robot.hear /give token (@\S+)+(\s|$)/, (msg) ->

  #   recipient = msg.match[1].toLowerCase()

  #   # if the sender has not given out any tokens yet, or 
  #   # if the sender has not already given out more that `max_tokens_per_user` tokens, 
  #   # then add recepient to @cacheTokens[sender]'s list
  #   if not(@cacheTokens[sender]?) or @cacheTokens[sender].length < max_tokens_per_user:
  #     @cacheTokens[sender] ?= [] # if @cacheTokens[sender] doesn't exist then set it equal to []
  #     @cacheTokens[sender] push recipient # add recipient to the list
  #     msg.send "#{msg.message.user.name} gave one token to #{recipient}"
  #     msg.send "#{msg.message.user.name} has given tokens to #{@cacheTokens[sender]}"


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