var eventBus, events, handleEvent, keys, log, mapKey, processEvents;

log = require('../../log');

eventBus = require('../../event-bus');

events = [];

handleEvent = function(game, event) {
  events.push(event);
  if (events.length === 1) {
    return process.nextTick(function() {
      processEvents(game, events);
      return events = [];
    });
  }
};

processEvents = function(game, events) {
  var ch, downEvent, key, name, pressEvent, ref, ref1;
  downEvent = events[0], pressEvent = events[1];
  log.silly('Key events:', events);
  ch = void 0;
  name = mapKey(downEvent.which);
  if (pressEvent != null) {
    ch = (ref = pressEvent.char) != null ? ref : String.fromCharCode(pressEvent.charCode);
    if (name == null) {
      name = ch.toLowerCase();
    }
  }
  key = {
    ch: ch,
    name: name,
    ctrl: downEvent.ctrlKey,
    shift: downEvent.shiftKey,
    alt: downEvent.altKey,
    meta: downEvent.metaKey
  };
  key.full = (key.ctrl ? 'C-' : '') + (key.meta ? 'M-' : '') + (key.shift ? 'S-' : '') + ((ref1 = key.name) != null ? ref1 : key.ch);
  return eventBus.emit("key." + key.name, key.ch, key);
};

mapKey = function(which) {
  return keys[which];
};

keys = {
  13: 'enter',
  27: 'escape',
  37: 'left',
  38: 'up',
  39: 'right',
  40: 'down'
};

module.exports = {
  handleEvent: handleEvent,
  processEvents: processEvents,
  mapKey: mapKey
};
