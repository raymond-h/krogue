var Effects, Prompts, Renderer, Web, eventBus, keyHandling,
  slice = [].slice;

eventBus = require('../../event-bus');

keyHandling = require('./keyhandling');

Renderer = require('./renderer');

Effects = require('./effects');

Prompts = require('./prompts');

module.exports = Web = (function() {
  function Web(game) {
    this.game = game;
  }

  Web.prototype.initializeLog = function(logLevel) {
    return (require('../../log')).initialize(logLevel, require('./log'));
  };

  Web.prototype.initialize = function() {
    var handle;
    handle = (function(_this) {
      return function() {
        var a;
        a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        return keyHandling.handleEvent.apply(keyHandling, [_this.game].concat(slice.call(a)));
      };
    })(this);
    $(document).keypress(handle);
    $(document).keydown(handle);
    this.renderer = new Renderer(this, this.game);
    this.effects = new Effects(this);
    this.prompts = new Prompts(this.game);
    return eventBus.on('action.toggle-graphics', (function(_this) {
      return function() {
        _this.renderer.useTiles = !_this.renderer.useTiles;
        return _this.renderer.invalidate();
      };
    })(this));
  };

  Web.prototype.deinitialize = function() {};

  return Web;

})();
