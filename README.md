# meshblu-websocket
Pure websocket implementation of the Meshblu client

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
