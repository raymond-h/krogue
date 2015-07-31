var eventBus, log;

eventBus = require('./event-bus');

log = require('./log');

module.exports = function(str) {
  log("<GAME> " + str);
  return eventBus.emit('log.add', str);
};
