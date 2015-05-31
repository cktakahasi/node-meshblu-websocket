Meshblu = require '../src/meshblu'

describe 'Meshblu', ->
  describe '->constructor', ->
    beforeEach ->
      @sut = new Meshblu

    it 'should be', ->
      expect(@sut).to.exist

  describe '->connect', ->
    describe 'when instantiated with node url params', ->
      beforeEach ->
        @WebSocket = sinon.spy()
        config = hostname: 'localhost', port: 1234
        @sut = new Meshblu config, WebSocket: @WebSocket
        @sut.connect()

      it 'should instantiate a new ws', ->
        expect(@WebSocket).to.have.been.calledWithNew

      it 'should have been called with a formated url', ->
        expect(@WebSocket).to.have.been.calledWith 'wss:localhost:1234/ws/v2'
