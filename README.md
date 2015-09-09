# meshblu-websocket
Pure websocket implementation of the Meshblu client

[![Build Status](https://travis-ci.org/octoblu/node-meshblu-websocket.svg?branch=master)](https://travis-ci.org/octoblu/node-meshblu-websocket)
[![npm version](https://badge.fury.io/js/meshblu-websocket.svg)](http://badge.fury.io/js/meshblu-websocket)
[![Gitter](https://badges.gitter.im/octoblu/help.svg)](https://gitter.im/octoblu/help)

### Install

```shell
npm install meshblu-websocket
```


### Example

```js
var MeshbluWebsocket = require('meshblu-websocket');
var MeshbluConfig = require('meshblu-config');

var meshbluConfig = new MeshbluConfig().toJSON();
var meshblu = new MeshbluWebsocket(meshbluConfig);

meshblu.connect(function(error){
  if (error) {
    console.error(error.message);
  }

  meshblu.subscribe({uuid: meshbluConfig.uuid});

  meshblu.on('config', function(data){
    console.log('config', data);
  });

  meshblu.updateDangerously({
    uuid: meshbluConfig.uuid,
    token: meshbluConfig.token
  }, {
    '$push': {
      stuff: {
        foo: 'bar'
      }
    }
  });
});
```
