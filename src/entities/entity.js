var _, direction, distanceSq, log,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

_ = require('lodash');

log = require('../log');

direction = require('rl-directions');

distanceSq = require('../util').distanceSq;

exports.Entity = (function() {
  Entity.prototype.blocking = false;

  function Entity(arg) {
    this.map = arg.map, this.x = arg.x, this.y = arg.y;
  }

  Entity.prototype.setPos = function(x, y) {
    var ref;
    if (_.isObject(x)) {
      ref = x, x = ref.x, y = ref.y;
    }
    this.x = x;
    return this.y = y;
  };

  Entity.prototype.movePos = function(x, y) {
    var ref;
    if (_.isString(x)) {
      x = direction.parse(x);
    }
    if (_.isObject(x)) {
      ref = x, x = ref.x, y = ref.y;
    }
    return this.setPos(this.x + x, this.y + y);
  };

  Entity.prototype.distanceSqTo = function(to) {
    return distanceSq(this, to);
  };

  Entity.prototype.distanceTo = function(to) {
    return Math.sqrt(this.distanceSqTo(to));
  };

  Entity.prototype.inRange = function(range, to) {
    return (this.distanceSqTo(to)) <= (range * range);
  };

  Entity.prototype.directionTo = function(to) {
    return direction.getDirection(this, to);
  };

  Entity.prototype.isPlayer = function() {
    return false;
  };

  Entity.prototype.tickRate = 0;

  Entity.prototype.tick = function() {};

  return Entity;

})();

exports.MapItem = (function(superClass) {
  extend(MapItem, superClass);

  MapItem.prototype.type = 'item';

  MapItem.prototype.blocking = false;

  function MapItem(arg) {
    this.item = arg.item;
    MapItem.__super__.constructor.apply(this, arguments);
  }

  return MapItem;

})(exports.Entity);

exports.Stairs = (function(superClass) {
  extend(Stairs, superClass);

  Stairs.prototype.type = 'stairs';

  Stairs.prototype.blocking = false;

  function Stairs(arg) {
    this.target = arg.target;
    Stairs.__super__.constructor.apply(this, arguments);
    if (this.target == null) {
      this.target = {};
    }
    this.down = false;
  }

  return Stairs;

})(exports.Entity);
