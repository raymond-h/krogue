var Effects, Promise, TtyEffects, bresenhamLine, log, ref, vectorMath, whilst,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Promise = require('bluebird');

Effects = require('../effects');

vectorMath = require('../../vector-math');

log = require('../../log');

ref = require('../../util'), bresenhamLine = ref.bresenhamLine, whilst = ref.whilst;

module.exports = TtyEffects = (function(superClass) {
  extend(TtyEffects, superClass);

  function TtyEffects() {
    return TtyEffects.__super__.constructor.apply(this, arguments);
  }

  TtyEffects.prototype["throw"] = function(arg) {
    var end, item, start, symbol;
    item = arg.item, start = arg.start, end = arg.end;
    symbol = this.io.renderer.getGraphic(item);
    return this.line({
      start: start,
      end: end,
      symbol: symbol,
      delay: 50
    });
  };

  TtyEffects.prototype.shootLine = function(arg) {
    var bullet, end, gun, start, symbol;
    gun = arg.gun, bullet = arg.bullet, start = arg.start, end = arg.end;
    symbol = this.io.renderer.getGraphic(bullet);
    return this.line({
      start: start,
      end: end,
      symbol: symbol,
      delay: 50
    });
  };

  TtyEffects.prototype.shootSpread = function(arg) {
    var a, angle, angles, bullet, end, gun, i, range, spread, start, symbol;
    gun = arg.gun, bullet = arg.bullet, start = arg.start, angle = arg.angle;
    spread = gun.spread, range = gun.range;
    symbol = this.io.renderer.getGraphic(bullet);
    angles = (function() {
      var j, results;
      results = [];
      for (i = j = -1; j <= 1; i = ++j) {
        results.push(angle + spread * i);
      }
      return results;
    })();
    return Promise.all((function() {
      var j, results;
      results = [];
      for (i = j = -1; j <= 1; i = ++j) {
        a = angle + spread * i;
        end = vectorMath.add(start, {
          x: Math.round(range * Math.cos(a)),
          y: -Math.round(range * Math.sin(a))
        });
        results.push(this.line({
          start: start,
          end: end,
          symbol: symbol,
          delay: 50
        }));
      }
      return results;
    }).call(this));
  };

  TtyEffects.prototype.line = function(arg) {
    var delay, end, points, start, symbol, time;
    start = arg.start, end = arg.end, time = arg.time, delay = arg.delay, symbol = arg.symbol;
    points = bresenhamLine(start, end);
    if ((time != null) && (delay == null)) {
      delay = time / points.length;
    }
    return this._performEffect({
      type: 'line',
      symbol: symbol
    }, function(data) {
      return whilst((function() {
        return points.length > 0;
      }), (function(_this) {
        return function() {
          return Promise["try"](function() {
            data.current = points.shift();
            return _this.invalidate();
          }).delay(delay);
        };
      })(this));
    });
  };

  TtyEffects.prototype.renderEffects = function(x, y) {
    var c, e, j, len, ox, oy, ref1, ref2, ref3, results;
    c = this.io.renderer.camera;
    ref1 = [x - c.x, y - c.y], ox = ref1[0], oy = ref1[1];
    ref2 = this.effects;
    results = [];
    for (j = 0, len = ref2.length; j < len; j++) {
      e = ref2[j];
      switch (e.type) {
        case 'line':
          ref3 = e.current, x = ref3.x, y = ref3.y;
          results.push(this.io.renderer.bufferPut(x + ox, y + oy, e.symbol));
          break;
        default:
          results.push(void 0);
      }
    }
    return results;
  };

  return TtyEffects;

})(Effects);
