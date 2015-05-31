url = require 'url'
_ = require 'lodash'

class Meshblu
  constructor: (@options={}, dependencies={})->
    @WebSocket = dependencies.WebSocket ? require 'ws'

  connect: =>
    uri = @_buildUri()
    @ws = new @WebSocket uri

  _buildUri: =>
    uriOptions = _.defaults @options, {
      protocol: 'wss'
      pathname: '/ws/v2'
    }

    url.format uriOptions

module.exports = Meshblu
