var Effects, Prompts, Renderer, Tty, blessed, eventBus, program;

blessed = require('blessed');

program = blessed.program();

eventBus = require('../../event-bus');

Renderer = require('./renderer');

Effects = require('./effects');

Prompts = require('./prompts');

module.exports = Tty = (function() {
  function Tty(game) {
    this.game = game;
  }

  Tty.prototype.initializeLog = function(logLevel) {
    return (require('../../log')).initialize(logLevel, require('./log'));
  };

  Tty.prototype.initialize = function() {
    program.reset();
    program.alternateBuffer();
    program.on('keypress', function(ch, key) {
      return eventBus.emit("key." + key.name, ch, key);
    });
    this.renderer = new Renderer(this, this.game);
    this.effects = new Effects(this);
    return this.prompts = new Prompts(this.game);
  };

  Tty.prototype.deinitialize = function() {
    program.clear();
    return program.normalBuffer();
  };

  return Tty;

})();
