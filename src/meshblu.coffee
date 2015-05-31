url             = require 'url'
{EventEmitter2} = require 'eventemitter2'
_               = require 'lodash'
debug           = require('debug')('meshblu')

PROXY_EVENTS = ['close', 'error', 'unexpected-response', 'ping', 'pong', 'open']

class Meshblu extends EventEmitter2
  constructor: (@options={}, dependencies={})->
    super wildcard: true
    @WebSocket = dependencies.WebSocket ? require 'ws'

  connect: (callback=->) =>
    @ws = new @WebSocket @_buildUri()
    @ws.once 'open', =>
      @send 'identity', _.pick(@options, 'uuid', 'token')

    readyHandler = (event) =>
      [type, data] = JSON.parse event
      debug 'readyHandler', [type, data]
      error = new Error(data.error.message) if data.error
      @ws.removeListener 'message', readyHandler
      callback error

    @ws.once 'message', readyHandler
    @ws.on 'message', @_messageHandler

    _.each PROXY_EVENTS, (event) => @_proxy event

  send: (type, data) =>
    throw new Error 'No Active Connection' unless @ws?
    debug 'send', [type, data]
    @ws.send JSON.stringify [type, data]

  whoami: (callback=->) =>
    @send 'whoami'

  _buildUri: =>
    uriOptions = _.defaults @options, {
      protocol: 'wss'
      pathname: '/ws/v2'
    }

    url.format uriOptions

  _messageHandler: (message) =>
    [type, data] = JSON.parse message
    @emit type, data

  _proxy: (event) =>
    @ws.on event, =>
      debug event, _.first arguments
      @emit event, arguments...


module.exports = Meshblu
