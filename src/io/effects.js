var Effects, _, p;

_ = require('lodash');

p = require('../util').p;

module.exports = Effects = (function() {
  function Effects(io) {
    this.io = io;
    this.effects = [];
  }

  Effects.prototype.doEffect = function(data) {
    var name;
    return typeof this[name = data.type] === "function" ? this[name](data) : void 0;
  };

  Effects.prototype._performEffect = function(data, cb) {
    this.effects.push(data);
    return p(cb.call(this, data)).then((function(_this) {
      return function() {
        _.pull(_this.effects, data);
        return _this.invalidate();
      };
    })(this));
  };

  Effects.prototype.invalidate = function() {
    return this.io.renderer.invalidate();
  };

  return Effects;

})();
