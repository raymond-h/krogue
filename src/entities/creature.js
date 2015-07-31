var Creature, Entity, MapItem, RangedValue, _, bresenhamLine, buffs, calc, creatureSpecies, direction, eventBus, game, items, log, p, pathFinding, random, ref, vectorMath,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

_ = require('lodash');

RangedValue = require('ranged-value');

log = require('../log');

game = require('../game');

random = require('../random');

eventBus = require('../event-bus');

bresenhamLine = require('../util').bresenhamLine;

p = require('../util').p;

direction = require('rl-directions');

vectorMath = require('../vector-math');

pathFinding = require('../path-finding');

creatureSpecies = require('../definitions/creature-species');

items = require('../definitions/items');

buffs = require('../definitions/buffs');

calc = require('../calc');

ref = require('./entity'), Entity = ref.Entity, MapItem = ref.MapItem;

module.exports = Creature = (function(superClass) {
  extend(Creature, superClass);

  Creature.prototype.type = 'creature';

  Creature.prototype.blocking = true;

  function Creature(arg) {
    var data, level;
    this.species = arg.species, data = arg.data;
    Creature.__super__.constructor.apply(this, arguments);
    if (data == null) {
      data = {};
    }
    this.personalities = data.personalities, this.inventory = data.inventory, this.equipment = data.equipment, this.xp = data.xp, level = data.level;
    if (this.species == null) {
      this.species = creatureSpecies.strangeGoo;
    }
    if (this.health == null) {
      this.health = new RangedValue({
        max: 30
      });
    }
    if ((this.health != null) && !(this.health instanceof RangedValue)) {
      this.health = new RangedValue(this.health);
    }
    if ((level != null) && (this.xp == null)) {
      this.xp = calc.xpForLevel(level);
    }
    if (this.xp == null) {
      this.xp = 0;
    }
    Object.defineProperties(this, {
      level: {
        get: (function(_this) {
          return function() {
            return calc.levelFromXp(_this.xp);
          };
        })(this),
        set: (function(_this) {
          return function(level) {
            return _this.setXp(calc.xpForLevel(level));
          };
        })(this)
      },
      weight: {
        get: (function(_this) {
          return function() {
            var ref1;
            return (ref1 = _this.species.weight) != null ? ref1 : 0;
          };
        })(this)
      }
    });
    if (this.personalities == null) {
      this.personalities = [];
    }
    if (this.inventory == null) {
      this.inventory = [];
    }
    if (this.equipment == null) {
      this.equipment = [];
    }
    if (this.buffs == null) {
      this.buffs = [];
    }
    if (this._skills == null) {
      this._skills = [];
    }
    this.recalculateStats();
  }

  Creature.prototype.isPlayer = function() {
    return this === game.player.creature;
  };

  Creature.prototype.setXp = function(xp) {
    var dlvl, newLvl, oldLvl;
    oldLvl = this.level;
    this.xp = xp;
    newLvl = this.level;
    if (newLvl !== oldLvl) {
      dlvl = newLvl - oldLvl;
      this.recalculateStats();
      return eventBus.emit('game.creature.level-change', this, newLvl, oldLvl);
    }
  };

  Creature.prototype.addXp = function(dxp) {
    return this.setXp(this.xp + dxp);
  };

  Creature.prototype.baseStat = function() {
    var params, ref1, stat;
    stat = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    if (stat === 'strength' || stat === 'endurance' || stat === 'agility') {
      return calc.creatureStat(this, stat);
    } else if (stat === 'health' || stat === 'attack' || stat === 'defense' || stat === 'speed' || stat === 'accuracy' || stat === 'weight' || stat === 'maxWeight') {
      return (ref1 = calc.stat)[stat].apply(ref1, [this].concat(slice.call(params)));
    }
  };

  Creature.prototype.stat = function() {
    var base, buff, i, item, j, len, len1, params, ref1, ref2, ref3, ref4, ref5, stat, val;
    stat = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    val = this.baseStat.apply(this, [stat].concat(slice.call(params)));
    val = (ref1 = typeof (base = this.species).modifyStat === "function" ? base.modifyStat.apply(base, [this, val, stat].concat(slice.call(params))) : void 0) != null ? ref1 : val;
    ref2 = this.equipment;
    for (i = 0, len = ref2.length; i < len; i++) {
      item = ref2[i];
      val = (ref3 = typeof item.modifyStat === "function" ? item.modifyStat.apply(item, [this, val, stat, slot].concat(slice.call(params))) : void 0) != null ? ref3 : val;
    }
    ref4 = this.buffs;
    for (j = 0, len1 = ref4.length; j < len1; j++) {
      buff = ref4[j];
      val = (ref5 = typeof item.modifyStat === "function" ? item.modifyStat.apply(item, [this, val, stat].concat(slice.call(params))) : void 0) != null ? ref5 : val;
    }
    return val;
  };

  Creature.prototype.calc = Creature.prototype.stat;

  Creature.prototype.recalculateStats = function() {
    var percent;
    percent = this.health.percent;
    this.health.max = this.stat('health');
    return this.health.percent = percent;
  };

  Creature.prototype.skills = function() {
    return slice.call(this.species.skills(this)).concat(slice.call(this._skills));
  };

  Creature.prototype.skill = function(name) {
    return _.find(this.skills(), function(skill) {
      return skill.name === name;
    });
  };

  Creature.prototype.overburdened = function() {
    return (calc.excessWeight(this)) > 0;
  };

  Creature.prototype.equipSlotCount = function(slot) {
    return this.equipment.map((function(_this) {
      return function(item) {
        return item.getEquipSlotUse(slot, _this);
      };
    })(this)).reduce((function(prev, curr) {
      return prev + curr;
    }), 0);
  };

  Creature.prototype.maxSpacesInSlot = function(slot) {
    return this.species.equipSlotNum[slot];
  };

  Creature.prototype.equipSlotFits = function(slot, item) {
    var maxSpaces;
    maxSpaces = this.maxSpacesInSlot(slot);
    return ((this.equipSlotCount(slot)) + (item.getEquipSlotUse(slot, this))) <= maxSpaces;
  };

  Creature.prototype.hasItemEquipped = function(item) {
    return indexOf.call(this.equipment, item) >= 0;
  };

  Creature.prototype.hasItemInSlot = function(slot, extraCheck) {
    return _.any(this.equipment, (function(_this) {
      return function(item) {
        var ref1;
        return (item.getEquipSlotUse(slot, _this)) > 0 && ((ref1 = typeof extraCheck === "function" ? extraCheck(item, slot) : void 0) != null ? ref1 : true);
      };
    })(this));
  };

  Creature.prototype.getItemsForSlot = function(slot) {
    return this.equipment.filter((function(_this) {
      return function(item) {
        return (item.getEquipSlotUse(slot, _this)) > 0;
      };
    })(this));
  };

  Creature.prototype.belongsToGroup = function(other) {
    if (_.isString(other)) {
      return (this.group != null) && this.group === other;
    }
    return (this.group != null) && (other.group != null) && this.group === other.group;
  };

  Creature.prototype.isGroupLeader = function(other) {
    return (this.leader != null) && this.belongsToGroup(other);
  };

  Creature.prototype.damage = function(dmg, cause) {
    eventBus.emit('game.creature.hurt', this, dmg, cause);
    this.health.current -= dmg;
    if (this.health.empty) {
      return this.die(cause);
    }
  };

  Creature.prototype.die = function(cause) {
    var corpse, drop, i, item, j, len, len1, ref1, ref2;
    drop = (function(_this) {
      return function(item) {
        var mapItem;
        mapItem = item.asMapItem(_this.x, _this.y);
        return _this.map.addEntity(mapItem);
      };
    })(this);
    if (!this.isPlayer()) {
      ref1 = this.inventory;
      for (i = 0, len = ref1.length; i < len; i++) {
        item = ref1[i];
        drop(item);
      }
      this.inventory = [];
      ref2 = this.equipment;
      for (j = 0, len1 = ref2.length; j < len1; j++) {
        item = ref2[j];
        drop(item);
      }
      this.equipment = [];
      corpse = new items.Corpse(this);
      drop(corpse);
      this.map.removeEntity(this);
    }
    eventBus.emit('game.creature.dead', this, cause);
    if (typeof cause.isPlayer === "function" ? cause.isPlayer() : void 0) {
      return cause.level++;
    }
  };

  Creature.prototype.pickup = function(item) {
    if (item instanceof MapItem) {
      if (this.pickup(item.item)) {
        this.map.removeEntity(item);
        return true;
      } else {
        return false;
      }
    }
    this.inventory.push(item);
    eventBus.emit('game.creature.pickup', this, item);
    return true;
  };

  Creature.prototype.drop = function(item) {
    var mapItem;
    if (!((item != null) && indexOf.call(this.inventory, item) >= 0)) {
      return false;
    }
    _.pull(this.inventory, item);
    mapItem = item.asMapItem(this.x, this.y);
    this.map.addEntity(mapItem);
    eventBus.emit('game.creature.drop', this, item);
    return true;
  };

  Creature.prototype.equip = function(item, silent) {
    var notFit;
    if (silent == null) {
      silent = false;
    }
    notFit = (function(_this) {
      return function(slot) {
        return !_this.equipSlotFits(slot, item);
      };
    })(this);
    if (_.any(creatureSpecies._equipSlots, notFit)) {
      return false;
    }
    _.pull(this.inventory, item);
    this.equipment.push(item);
    if (!silent) {
      eventBus.emit('game.creature.equip', this, item);
    }
    return true;
  };

  Creature.prototype.unequip = function(item, silent) {
    if (silent == null) {
      silent = false;
    }
    log.info("Is it equipped already? " + (this.hasItemEquipped(item)));
    if (this.hasItemEquipped(item)) {
      _.pull(this.equipment, item);
      this.inventory.push(item);
      eventBus.emit('game.creature.unequip', this, item);
      return true;
    } else {
      return false;
    }
  };

  Creature.prototype["throw"] = function(item, offset) {
    var endPos, found, ref1;
    if (_.isString(offset)) {
      offset = vectorMath.mult(direction.parse(offset), 15);
    }
    endPos = vectorMath.add(this, offset);
    _.pull(this.inventory, item);
    found = this.raytraceUntilBlocked(endPos, {
      range: 15
    });
    if ((ref1 = found.type) === 'creature' || ref1 === 'none') {
      endPos = found;
    } else if (found.type === 'wall') {
      endPos = found.checked[1];
    }
    return game.effects["throw"]({
      item: item,
      start: this,
      end: endPos
    }).then((function(_this) {
      return function() {
        var dealDamage, hit, mapItem, r, target;
        hit = false;
        if (found.type === 'creature') {
          target = found.creature;
          dealDamage = function() {
            return target.damage(5, _this);
          };
          r = typeof item.onHit === "function" ? item.onHit(_this.map, endPos, target, dealDamage) : void 0;
          if (r !== false) {
            dealDamage();
          }
          hit = true;
        }
        mapItem = item.asMapItem(endPos.x, endPos.y);
        _this.map.addEntity(mapItem);
        return typeof item.onLand === "function" ? item.onLand(_this.map, endPos, hit) : void 0;
      };
    })(this));
  };

  Creature.prototype.move = function(x, y) {
    var canMoveThere, ref1;
    if (_.isString(x)) {
      x = direction.parse(x);
    }
    if (_.isObject(x)) {
      ref1 = x, x = ref1.x, y = ref1.y;
    }
    canMoveThere = !this.collidable(this.x + x, this.y + y);
    if (canMoveThere) {
      this.movePos(x, y);
    }
    return canMoveThere;
  };

  Creature.prototype.moveTo = function(p, pathfind) {
    var path, ref1, status;
    if (pathfind == null) {
      pathfind = false;
    }
    if (!pathfind) {
      return this.move(this.directionTo(p));
    } else {
      ref1 = pathFinding.aStarOverDistanceMap(this.map, this, p), status = ref1.status, path = ref1.path;
      if (status === 'success') {
        return this.move(vectorMath.sub(path[1], this));
      } else {
        return false;
      }
    }
  };

  Creature.prototype.moveAwayFrom = function(p) {
    return this.move(direction.opposite(this.directionTo(p)));
  };

  Creature.prototype.attack = function(dir) {
    var creatures, dmg, item, ref1, target, x, y;
    ref1 = direction.parse(dir), x = ref1.x, y = ref1.y;
    x += this.x;
    y += this.y;
    if (this.map.collidable(x, y)) {
      eventBus.emit('game.creature.attack.wall', this, dir);
      this.damage(3, 'attacking a wall');
      return true;
    } else {
      creatures = this.map.entitiesAt(x, y, 'creature');
      if (creatures.length > 0) {
        target = creatures[0];
        eventBus.emit('game.creature.attack.creature', this, dir, target);
        item = random.sample(this.getItemsForSlot('hand'));
        dmg = calc.meleeDamage(this, item, target);
        target.damage(dmg, this);
        return true;
      } else {
        eventBus.emit('game.creature.attack.none', this, dir);
        return false;
      }
    }
  };

  Creature.prototype.findNearest = function(maxRange, cb) {
    var dSq, e, i, len, minDist, nearest, ref1, ref2;
    if (maxRange == null) {
      maxRange = Infinity;
    }
    minDist = maxRange * maxRange;
    nearest = null;
    ref1 = this.map.entities;
    for (i = 0, len = ref1.length; i < len; i++) {
      e = ref1[i];
      if (!(!(e === this) && cb(e))) {
        continue;
      }
      dSq = this.distanceSqTo(e);
      if (dSq < minDist) {
        ref2 = [dSq, e], minDist = ref2[0], nearest = ref2[1];
      }
    }
    return nearest;
  };

  Creature.prototype.canSee = function(to) {
    var visible;
    visible = true;
    bresenhamLine(this, to, (function(_this) {
      return function(x, y) {
        if (x === to.x && y === to.y) {
          return;
        }
        if (!_this.map.seeThrough(x, y)) {
          return visible = false;
        }
      };
    })(this));
    return visible;
  };

  Creature.prototype.raytraceUntilBlocked = function(to, opts, cb) {
    var checked, found, ref1;
    if (opts == null) {
      opts = {};
    }
    if (_.isFunction(opts)) {
      ref1 = [{}, opts], opts = ref1[0], cb = ref1[1];
    }
    if (opts.range == null) {
      opts.range = Infinity;
    }
    checked = [];
    found = {
      type: 'none'
    };
    bresenhamLine(this, to, (function(_this) {
      return function(x, y) {
        var creatures;
        if ((_this.distanceSqTo({
          x: x,
          y: y
        })) > (opts.range * opts.range)) {
          return false;
        }
        found.x = x;
        found.y = y;
        checked.unshift({
          x: x,
          y: y
        });
        if (x === _this.x && y === _this.y) {
          return;
        }
        if (_this.map.collidable(x, y)) {
          found = {
            type: 'wall',
            x: x,
            y: y
          };
          return false;
        }
        creatures = _this.map.entitiesAt(x, y, 'creature');
        if (creatures.length > 0) {
          found = {
            type: 'creature',
            creature: creatures[0],
            x: x,
            y: y
          };
          return false;
        }
      };
    })(this));
    found.checked = checked;
    return found;
  };

  Creature.prototype.collidable = function(x, y) {
    return (this.map.collidable(x, y)) || (this.map.hasBlockingEntities(x, y));
  };

  Creature.prototype.tickRate = function() {
    return this.calc('speed');
  };

  Creature.prototype.tick = function() {
    var a, ref1;
    a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    if (this.isPlayer()) {
      return (ref1 = game.player).tick.apply(ref1, a);
    } else {
      return this.aiTick.apply(this, a);
    }
  };

  Creature.prototype.aiTick = function() {
    var choices, groups, weights;
    if (this.personalities.length === 0) {
      return this.tickRate();
    }
    groups = _.omit(_.groupBy(this.personalities, (function(_this) {
      return function(p) {
        var ref1;
        return (p.weight(_this)) * ((ref1 = p.weightMultiplier) != null ? ref1 : 1);
      };
    })(this)), '0');
    weights = _.keys(groups);
    if (weights.length === 0) {
      return this.tickRate();
    }
    choices = groups[Math.max.apply(Math, weights)];
    if (choices.length >= 2) {
      return this.tickRate();
    }
    return choices[0].tick(this);
  };

  return Creature;

})(Entity);
