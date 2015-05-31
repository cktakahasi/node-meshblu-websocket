{EventEmitter} = require 'events'
Meshblu        = require '../src/meshblu'

describe 'Meshblu', ->
  beforeEach ->
    @ws = new WebSocket
    @WebSocket = sinon.stub().returns @ws

  describe '->connect', ->
    describe 'when instantiated with node url params', ->
      beforeEach ->
        config = {
          hostname: 'localhost'
          port: 1234
          uuid: 'some-uuid'
          token: 'some-token'
        }
        @callback = sinon.spy()

        @sut = new Meshblu config, WebSocket: @WebSocket
        @sut.connect @callback

      it 'should instantiate a new ws', ->
        expect(@WebSocket).to.have.been.calledWithNew

      it 'should have been called with a formated url', ->
        expect(@WebSocket).to.have.been.calledWith 'wss:localhost:1234/ws/v2'

      describe 'when the WebSocket emits open', ->
        beforeEach ->
          @ws.emit 'open'

        it 'should send identity', ->
          expect(@ws.send).to.have.been.calledWith '["identity",{"uuid":"some-uuid","token":"some-token"}]'

      describe 'when the WebSocket emits ready', ->
        beforeEach ->
          @ws.emit 'message', '["ready",{}]'

        it 'should call the callback', ->
          expect(@callback).to.have.been.called

      describe 'when the WebSocket emits notready', ->
        beforeEach ->
          @ws.emit 'message', '["notready",{"error":{"message":"Unauthorized"}}]'

        it 'should call the callback with the error', ->
          expect(@callback).to.have.been.calledWith new Error('Unauthorized')



class WebSocket extends EventEmitter
  constructor: ->
    sinon.spy this, 'send'

  send: =>
