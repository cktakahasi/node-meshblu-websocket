_               = require 'lodash'
url             = require 'url'
{EventEmitter2} = require 'eventemitter2'
_               = require 'lodash'
debug           = require('debug')('meshblu-websocket')

PROXY_EVENTS = ['close', 'error', 'unexpected-response', 'ping', 'pong', 'open']
FIVE_MINUTES = 5 * 60 * 1000

class Meshblu extends EventEmitter2
  constructor: (options={}, dependencies={})->
    super wildcard: true
    @WebSocket = dependencies.WebSocket ? require 'ws'
    @dns       = dependencies.dns ? require 'dns'
    @pingInterval ?= 15000
    @pingTimeout  ?= FIVE_MINUTES

    {@protocol, @hostname, @port} = options
    {@service, @domain, @secure, @resolveSrv} = options
    @credentials = _.pick options, 'uuid', 'token'

  close: =>
    clearInterval @_pollPingInterval
    @ws?.close()

  connect: (callback=->) =>
    @_resolveBaseUrl (error, baseUrl) =>
      return callback error if error?

      @ws = new @WebSocket baseUrl
      @ws.once 'open', => @identity @credentials
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
    @_pollPingInterval = setInterval @ping, @pingInterval

  ping: =>
    debug 'ping'
    try
      @ws?.ping()
    catch error
      return @emit 'error', error

    elapsedTime = Date.now() - @_lastPong
    if elapsedTime > @pingTimeout
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
      pathname: '/ws/v2'
    }

    if @options.port == 443
      uriOptions.protocol = 'wss'
    else
      uriOptions.protocol ?= 'ws'

    url.format uriOptions

  _getSrvAddress: =>
    return "_#{@service}._#{@_getSrvProtocol()}.#{@domain}"

  _getSrvProtocol: =>
    return 'wss' if @secure
    return 'ws'

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

  _resolveBaseUrl: (callback) =>
    return callback null, @_resolveNormalUrl() unless @resolveSrv

    @dns.resolveSrv @_getSrvAddress(), (error, addresses) =>
      return callback error if error?
      return callback new Error('SRV record found, but contained no valid addresses') if _.isEmpty addresses
      return callback null, @_resolveUrlFromAddresses(addresses)

  _resolveNormalUrl: =>
    pathname = '/ws/v2'
    protocol = @protocol ? 'ws'
    protocol = 'ws' if @protocol == 'http'
    protocol = 'wss' if @port == 443 || @protocol == 'https'

    url.format {protocol, @hostname, @port, pathname}

  _resolveUrlFromAddresses: (addresses) =>
    address = _.minBy addresses, 'priority'
    return url.format {
      protocol: @_getSrvProtocol()
      hostname: address.name
      port: address.port
      pathname: '/ws/v2'
    }

  _uuidOrObject: (data) =>
    return uuid: data if _.isString data
    return data

module.exports = Meshblu
