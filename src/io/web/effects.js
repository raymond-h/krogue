var Effects, Promise, WebEffects, bresenhamLine, ref, vectorMath, whilst,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Promise = require('bluebird');

Effects = require('../effects');

vectorMath = require('../../vector-math');

ref = require('../../util'), bresenhamLine = ref.bresenhamLine, whilst = ref.whilst;

module.exports = WebEffects = (function(superClass) {
  extend(WebEffects, superClass);

  function WebEffects() {
    return WebEffects.__super__.constructor.apply(this, arguments);
  }

  WebEffects.prototype["throw"] = function(arg) {
    var end, item, start;
    item = arg.item, start = arg.start, end = arg.end;
    return Promise.resolve(null);
  };

  WebEffects.prototype.shootLine = function(arg) {
    var bullet, end, gun, start;
    gun = arg.gun, bullet = arg.bullet, start = arg.start, end = arg.end;
    return Promise.resolve(null);
  };

  WebEffects.prototype.shootSpread = function(arg) {
    var angle, bullet, gun, start;
    gun = arg.gun, bullet = arg.bullet, start = arg.start, angle = arg.angle;
    return Promise.resolve(null);
  };

  WebEffects.prototype.line = function(arg) {
    var delay, end, start, symbol, time;
    start = arg.start, end = arg.end, time = arg.time, delay = arg.delay, symbol = arg.symbol;
    return Promise.resolve(null);
  };

  WebEffects.prototype.renderEffects = function(ox, oy) {
    var e, i, len, ref1, ref2, results, x, y;
    ref1 = this.effects;
    results = [];
    for (i = 0, len = ref1.length; i < len; i++) {
      e = ref1[i];
      switch (e.type) {
        case 'line':
          ref2 = e.current, x = ref2.x, y = ref2.y;
          results.push(this.io.renderer.renderGraphicAtSlot(x + ox, y + oy, e.symbol));
          break;
        default:
          results.push(void 0);
      }
    }
    return results;
  };

  return WebEffects;

})(Effects);
