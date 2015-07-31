var Item, _, calc, direction, eventBus, game, log, message, random, vectorMath,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

_ = require('lodash');

direction = require('rl-directions');

game = require('../game');

random = require('../random');

eventBus = require('../event-bus');

message = require('../message');

vectorMath = require('../vector-math');

calc = require('../calc');

log = require('../log');

Item = exports.Item = (function() {
  function Item() {}

  Item.prototype.getEquipSlotUse = function(slot, creature) {
    if (slot === 'hand') {
      return calc.itemSlotUse(creature, this);
    } else {
      return 0;
    }
  };

  Item.prototype.equipSlotUse = function() {
    return (require('./creature-species'))._equipSlots.map((function(_this) {
      return function(slot) {
        return _this.getEquipSlotUse(slot);
      };
    })(this));
  };

  Item.prototype.copy = function() {
    var c;
    c = new this.constructor;
    _.assign(c, this);
    return c;
  };

  Item.prototype.equipSlotUseString = function(creature) {
    return (require('./creature-species'))._equipSlots.filter((function(_this) {
      return function(slot) {
        return (_this.getEquipSlotUse(slot, creature)) > 0;
      };
    })(this)).map((function(_this) {
      return function(slot) {
        var count;
        log.info("Slot " + slot + " is go!");
        count = _this.getEquipSlotUse(slot, creature);
        if (count === 1) {
          return slot;
        } else {
          return count + " " + slot;
        }
      };
    })(this)).join(', ');
  };

  Item.prototype.asMapItem = function(x, y) {
    var MapItem;
    MapItem = require('../entities').MapItem;
    return new MapItem({
      x: x,
      y: y,
      item: this
    });
  };

  return Item;

})();

exports.PeculiarObject = (function(superClass) {
  extend(PeculiarObject, superClass);

  function PeculiarObject() {
    return PeculiarObject.__super__.constructor.apply(this, arguments);
  }

  PeculiarObject.prototype.name = 'peculiar object';

  return PeculiarObject;

})(Item);

exports.Corpse = (function(superClass) {
  extend(Corpse, superClass);

  Corpse.prototype.name = 'unknown corpse';

  function Corpse(creature1) {
    this.creature = creature1;
    Object.defineProperties(this, {
      name: {
        get: (function(_this) {
          return function() {
            var name, ref;
            name = (ref = _this.creature.name) != null ? ref : _this.creature.species.name;
            return "corpse of " + name;
          };
        })(this)
      },
      weight: {
        get: (function(_this) {
          return function() {
            return _this.creature.calc('weight');
          };
        })(this)
      }
    });
  }

  return Corpse;

})(Item);

exports.PokeBall = (function(superClass) {
  extend(PokeBall, superClass);

  PokeBall.prototype.name = 'poké ball';

  PokeBall.prototype.rates = {
    'normal': 1,
    'great': 1.5,
    'ultra': 2,
    'master': 255
  };

  PokeBall.prototype.names = {
    'normal': 'poké ball',
    'great': 'great ball',
    'ultra': 'ultra ball',
    'master': 'master ball'
  };

  function PokeBall(type, creature1) {
    this.type = type != null ? type : null;
    this.creature = creature1 != null ? creature1 : null;
    Object.defineProperty(this, 'name', {
      get: (function(_this) {
        return function() {
          var name, ref, ref1, ref2;
          if (_this.creature != null) {
            name = (ref = _this.creature.name) != null ? ref : _this.creature.species.name;
            return _this.names[(ref1 = _this.type) != null ? ref1 : 'normal'] + " w/ " + name;
          } else {
            return _this.names[(ref2 = _this.type) != null ? ref2 : 'normal'];
          }
        };
      })(this)
    });
  }

  PokeBall.prototype.calcRate = function(target) {
    var ref;
    return 190 * this.rates[(ref = this.type) != null ? ref : 'normal'];
  };

  PokeBall.prototype.catchRate = function(target) {
    var currHp, maxHp, ref;
    ref = target.health, maxHp = ref.max, currHp = ref.current;
    return (3 * maxHp - 2 * currHp) / (3 * maxHp) * this.calcRate(target);
  };

  PokeBall.prototype.catchProb = function(target) {
    var a, b;
    if (this.type === 'master') {
      return 1;
    }
    a = this.catchRate(target);
    if (a >= 255) {
      return 1;
    }
    b = 1048560 / Math.sqrt(Math.sqrt(16711680 / a));
    return Math.pow((b + 1) / (1 << 16), 4);
  };

  PokeBall.prototype.onHit = function(map, pos, target) {
    var catchProb, lines, name, ref;
    if (this.creature == null) {
      catchProb = this.catchProb(target);
      if (random.chance(catchProb)) {
        map.removeEntity(target);
        this.creature = target;
        name = (ref = target.name) != null ? ref : 'The ' + target.species.name;
        message("Gotcha! " + name + " was caught!");
      } else {
        lines = ['Oh, no! The creature broke free!', 'Aww! It appeared to be caught!', 'Aargh! Almost had it!', 'Shoot! It was so close, too!'];
        message(random.sample(lines));
      }
      return false;
    }
  };

  PokeBall.prototype.onLand = function(map, pos, hit) {
    var lines, ref;
    if ((this.creature != null) && !hit) {
      map.addEntity(this.creature);
      this.creature.setPos(pos);
      lines = ['Go', 'This is your chance! Go', 'The opponent is weak, finish them! Go'];
      message((random.sample(lines)) + " " + ((ref = this.creature.name) != null ? ref : this.creature.species.name) + "!");
      return this.creature = null;
    }
  };

  return PokeBall;

})(Item);

exports.Bullet = (function(superClass) {
  extend(Bullet, superClass);

  Bullet.prototype.name = 'bullet';

  Bullet.prototype.leaveWhenShot = false;

  function Bullet(type) {
    this.type = type != null ? type : 'medium';
    Object.defineProperty(this, 'name', {
      get: (function(_this) {
        return function() {
          return _this.type + " bullet";
        };
      })(this)
    });
  }

  Bullet.prototype.onHit = function(map, pos, target, dealDamage) {};

  Bullet.prototype.onLand = function(map, pos, target, dealDamage) {};

  return Bullet;

})(Item);

exports.BulletPack = (function(superClass) {
  extend(BulletPack, superClass);

  BulletPack.prototype.name = 'pack of ammo';

  function BulletPack(ammo, amount) {
    this.ammo = ammo != null ? ammo : new exports.Bullet;
    this.amount = amount != null ? amount : 1;
    Object.defineProperty(this, 'name', {
      get: (function(_this) {
        return function() {
          return "pack of " + _this.amount + "x ammo (" + _this.ammo.name + ")";
        };
      })(this)
    });
  }

  BulletPack.prototype.reload = function(ammoItem) {
    if (ammoItem instanceof exports.BulletPack && _.isEqual(ammoItem.ammo, this.ammo)) {
      this.amount += ammoItem.amount;
      return true;
    } else if (_.isEqual(ammoItem, this.ammo)) {
      this.amount += 1;
      return true;
    } else {
      return false;
    }
  };

  return BulletPack;

})(Item);

exports.Gun = (function(superClass) {
  extend(Gun, superClass);

  Gun.prototype.name = 'gun';

  function Gun(ammo) {
    this.ammo = ammo != null ? ammo : [];
  }

  Gun.prototype.fire = function() {
    var a, fn;
    a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    fn = this.fireHandlers[this.fireType()];
    return fn.apply(this, a);
  };

  Gun.prototype.reload = function(ammoItem) {
    var i, j, ref, util;
    if (ammoItem instanceof exports.BulletPack) {
      for (i = j = 1, ref = ammoItem.amount; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        this.ammo.push(ammoItem.ammo.copy());
      }
    } else {
      this.ammo.push(ammoItem);
    }
    util = require('util');
    log.info("Current ammo after reload: " + (util.inspect(this.ammo)) + " (" + this.ammo.length + ")");
    return true;
  };

  Gun.prototype.fireType = function() {
    switch (this.gunType) {
      case 'handgun':
      case 'sniper':
        return 'line';
      case 'shotgun':
        return 'spread';
      default:
        return '_dud';
    }
  };

  Gun.prototype.pullCurrentAmmo = function() {
    var currentAmmo;
    currentAmmo = this.ammo.shift();
    log.info("Current ammo: " + ((require('util')).inspect(this.ammo)) + " (" + this.ammo.length + ")");
    return currentAmmo;
  };

  Gun.prototype.fireHandlers = {
    '_dud': function(creature, offset) {
      return message('Nothing happens; this gun is a dud.');
    },
    'line': function(creature, offset) {
      var currentAmmo, endPos, found, ref;
      currentAmmo = this.pullCurrentAmmo();
      if (currentAmmo == null) {
        eventBus.emit('game.creature.fire.empty', creature, this, offset);
        return;
      }
      eventBus.emit('game.creature.fire', creature, this, offset);
      if (_.isString(offset)) {
        offset = vectorMath.mult(direction.parse(offset), this.range);
      }
      endPos = vectorMath.add(creature, offset);
      found = creature.raytraceUntilBlocked(endPos, {
        range: this.range
      });
      if ((ref = found.type) === 'creature' || ref === 'none') {
        endPos = found;
      } else if (found.type === 'wall') {
        endPos = found.checked[1];
      }
      return game.effects.shootLine({
        gun: this,
        bullet: currentAmmo,
        start: creature,
        end: found
      }).then((function(_this) {
        return function() {
          var dealDamage, dmg, hit, map, mapItem, r, ref1, target;
          map = creature.map;
          hit = false;
          switch (found.type) {
            case 'none':
              eventBus.emit('game.creature.fire.hit.none', creature, _this, offset);
              break;
            case 'wall':
              eventBus.emit('game.creature.fire.hit.wall', creature, _this, offset, found);
              break;
            case 'creature':
              target = found.creature;
              dmg = calc.gunDamage(creature, _this, target);
              dealDamage = function() {
                return target.damage(dmg, creature);
              };
              eventBus.emit('game.creature.fire.hit.creature', creature, _this, offset, target);
              r = typeof currentAmmo.onHit === "function" ? currentAmmo.onHit(map, found, target, dealDamage) : void 0;
              if (r !== false) {
                dealDamage();
              }
              hit = true;
          }
          if ((ref1 = currentAmmo.leaveWhenShot) != null ? ref1 : true) {
            mapItem = currentAmmo.asMapItem(endPos.x, endPos.y);
            map.addEntity(mapItem);
          }
          if (typeof currentAmmo.onLand === "function") {
            currentAmmo.onLand(map, endPos, hit);
          }
        };
      })(this));
    },
    'spread': function(creature, offset) {
      var angle, compareAngles, currentAmmo;
      currentAmmo = this.pullCurrentAmmo();
      if (currentAmmo == null) {
        eventBus.emit('game.creature.fire.empty', creature, this, offset);
        return;
      }
      eventBus.emit('game.creature.fire', creature, this, offset);
      if (_.isString(offset)) {
        offset = direction.parse(offset);
      }
      angle = Math.atan2(-offset.y, offset.x);
      compareAngles = function(a0, a1) {
        return Math.PI - Math.abs(Math.abs(a0 - a1) - Math.PI);
      };
      return game.effects.shootSpread({
        gun: this,
        bullet: currentAmmo,
        start: creature,
        angle: angle
      }).then((function(_this) {
        return function() {
          var dmg, j, len, results, target, targets;
          targets = creature.map.listEntities(function(e) {
            var a, diff;
            if (e === creature) {
              return false;
            }
            if (e.type !== 'creature') {
              return;
            }
            diff = vectorMath.sub(e, creature);
            a = Math.atan2(-diff.y, diff.x);
            return (compareAngles(angle, a)) <= _this.spread / 2 && (creature.distanceSqTo(e)) <= (_this.range * _this.range) && creature.canSee(e);
          });
          if (targets.length > 0) {
            results = [];
            for (j = 0, len = targets.length; j < len; j++) {
              target = targets[j];
              dmg = calc.gunDamage(creature, _this, target);
              eventBus.emit('game.creature.fire.hit.creature', creature, _this, offset, target);
              results.push(target.damage(dmg, creature));
            }
            return results;
          } else {
            return eventBus.emit('game.creature.fire.hit.none', creature, _this, offset);
          }
        };
      })(this));
    }
  };

  return Gun;

})(Item);
