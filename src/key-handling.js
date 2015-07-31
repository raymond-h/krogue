var _, bindings, direction, eventBus,
  slice = [].slice;

_ = require('lodash');

direction = require('rl-directions');

bindings = require('../key-bindings.json');

eventBus = require('./event-bus');

eventBus.on('key.*', function(ch, key) {
  var action, parts, ref;
  action = (ref = bindings[key.full]) != null ? ref : bindings[key.name];
  if (action != null) {
    parts = action.split('.');
    if (parts[0] === 'direction') {
      parts[1] = direction.normalize(parts[1], 1);
    }
    return eventBus.emit.apply(eventBus, ["action." + (parts.join('.'))].concat(slice.call(parts)));
  }
});

exports.bindings = bindings;
