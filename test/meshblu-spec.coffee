{EventEmitter} = require 'events'
Meshblu        = require '../src/meshblu'

describe 'Meshblu', ->
  beforeEach ->
    @ws = new WebSocket
    @WebSocket = sinon.stub().returns @ws

  describe '->close', ->
    describe 'with a connected client', ->
      beforeEach (done) ->
        @sut = new Meshblu {}, WebSocket: @WebSocket
        @sut.connect done
        @ws.emit 'message', '["ready"]'

      describe 'when called', ->
        beforeEach ->
          @sut.close()

        it 'should call close on the @ws', ->
          expect(@ws.close).to.have.been.called

    describe 'with a disconnected client', ->
      beforeEach ->
        @sut = new Meshblu {}, WebSocket: @WebSocket

      describe 'when called', ->
        it 'should not throw an error', ->
          expect(@sut.close).not.to.throw

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

      afterEach ->
        @sut.close()

      it 'should instantiate a new ws', ->
        expect(@WebSocket).to.have.been.calledWithNew

      it 'should have been called with a formated url', ->
        expect(@WebSocket).to.have.been.calledWith 'ws:localhost:1234/ws/v2'

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
          @ws.emit 'message', '["notReady",{"message":"Unauthorized"}]'

        it 'should call the callback with the error', ->
          expect(@callback.firstCall.args[0]).to.be.an.instanceOf Error
          expect(@callback.firstCall.args[0].message).to.deep.equal 'Unauthorized'

class WebSocket extends EventEmitter
  constructor: ->
    sinon.stub this, 'send'
    sinon.stub this, 'close'

  send: =>
  close: =>
