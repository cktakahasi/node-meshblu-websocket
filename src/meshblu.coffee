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
      @identity _.pick(@options, 'uuid', 'token')

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

  # API Functions
  device:      (params) => @send 'device', params
  devices:     (params) => @send 'devices', params
  identity:    (params) => @send 'identity', params
  message:     (params) => @send 'message', params
  mydevices:   (params) => @send 'mydevices', params
  register:    (params) => @send 'register', params
  subscribe:   (params) => @send 'subscribe', params
  unsubscribe: (params) => @send 'unsubscribe', params
  update:      (params) => @send 'update', params
  whoami:               => @send 'whoami'
  unregister:  (params) => @send 'unregister', params

  # Private Functions

  _buildUri: =>
    uriOptions = _.defaults @options, {
      protocol: 'wss'
      pathname: '/ws/v2'
    }

    url.format uriOptions

  _messageHandler: (message) =>
    debug '_messageHandler', message
    [type, data] = JSON.parse message
    return @emit type, data unless type == 'error'
    return @emit 'error', new Error(data.message) if data.message
    @emit 'error', new Error("unknown error occured, here's what I know: #{JSON.stringify(data)}")

  _proxy: (event) =>
    @ws.on event, =>
      debug event, _.first arguments
      @emit event, arguments...


module.exports = Meshblu
