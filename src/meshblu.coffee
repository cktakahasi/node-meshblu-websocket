_               = require 'lodash'
url             = require 'url'
{EventEmitter2} = require 'eventemitter2'
_               = require 'lodash'
debug           = require('debug')('meshblu-websocket')

PROXY_EVENTS = ['close', 'error', 'unexpected-response', 'ping', 'pong', 'open']
FIVE_MINUTES = 5 * 60 * 1000

class Meshblu extends EventEmitter2
  constructor: (@options={}, dependencies={})->
    super wildcard: true
    @WebSocket = dependencies.WebSocket ? require 'ws'
    @options.pingInterval ?= 15000
    @options.pingTimeout  ?= FIVE_MINUTES

  close: =>
    clearInterval @_pollPingInterval
    @ws?.close()

  connect: (callback=->) =>
    @ws = new @WebSocket @_buildUri()
    @ws.once 'open', =>
      @identity _.pick(@options, 'uuid', 'token')
    @startPollPinging()

    readyHandler = (event) =>
      [type, data] = JSON.parse event
      debug 'readyHandler', [type, data]
      if type == 'notReady' || type == 'error'
        error = new Error data.message
        error.status = data.status
        error.frame = data.frame
        return callback error
      @ws.removeListener 'message', readyHandler
      callback()

    @ws.once 'message', readyHandler
    @ws.on 'message', @_messageHandler
    @ws.on 'pong', @_handlePong

    _.each PROXY_EVENTS, (event) => @_proxy event

  reconnect: =>
    debug 'reconnect'
    @ws.close()
    @ws.removeAllListeners('ready')
    @connect()

  startPollPinging: =>
    return if @_alreadyPollPinging
    @_alreadyPollPinging = true
    @_pollPingInterval = setInterval @ping, @options.pingInterval

  ping: =>
    debug 'ping'
    try
      @ws?.ping()
    catch error
      return @emit 'error', error

    elapsedTime = Date.now() - @_lastPong
    if elapsedTime > @options.pingTimeout
      @emit 'error', new Error('Ping Timeout')

  send: (type, data) =>
    throw new Error 'No Active Connection' unless @ws?
    debug 'send', [type, data]
    @ws.send JSON.stringify [type, data]

  # API Functions
  device: (params) =>
    params = @_uuidOrObject params
    @send 'device', params

  devices: (params) =>
    @send 'devices', params

  identity: (params) =>
    @send 'identity', params

  message: (params) =>
    @send 'message', params

  mydevices: (params) =>
    @send 'mydevices', params

  register: (params) =>
    @send 'register', params

  subscribe: (params) =>
    params = @_uuidOrObject params
    @send 'subscribe', params

  subscribelist: =>
    @send 'subscribelist'

  unsubscribe: (params) =>
    params = @_uuidOrObject params
    @send 'unsubscribe', params

  update: (query, params) =>
    @send 'update', [query, {$set: params}]

  updateDangerously: (query, params) =>
    @send 'update', [query, params]

  whoami: =>
    @send 'whoami'

  unregister: (params) =>
    params = @_uuidOrObject params
    @send 'unregister', params

  # Private Functions

  _buildUri: =>
    uriOptions = _.defaults @options, {
      protocol: 'wss'
      pathname: '/ws/v2'
    }

    url.format uriOptions

  _handlePong: =>
    @_lastPong = Date.now()

  _messageHandler: (message) =>
    debug '_messageHandler', message
    [type, data] = JSON.parse message
    return @emit type, data unless type == 'error'
    if data.message?
      error = new Error data.message
      error.frame = data.frame
      error.status = data.status
      return @emit 'error', error
    @emit 'error', new Error("unknown error occured, here's what I know: #{JSON.stringify(data)}")

  _proxy: (event) =>
    @ws.on event, =>
      debug event, _.first arguments
      @emit event, arguments...

  _uuidOrObject: (data) =>
    return uuid: data if _.isString data
    return data

module.exports = Meshblu
