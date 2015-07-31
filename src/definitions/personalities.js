var Personality, _, direction, game, items, p, random, vectorMath,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

_ = require('lodash');

game = require('../game');

random = require('../random');

items = require('./items');

direction = require('rl-directions');

vectorMath = require('../vector-math');

p = require('../util').p;

Personality = exports.Personality = (function() {
  function Personality(creature) {
    this.creature = creature;
    this.weightMultiplier = 1;
  }

  Personality.prototype.withMultiplier = function(weightMultiplier) {
    this.weightMultiplier = weightMultiplier;
    return this;
  };

  Personality.prototype.weight = function() {
    return 0;
  };

  Personality.prototype.tick = function() {
    return 0;
  };

  return Personality;

})();

exports.FleeFromPlayer = (function(superClass) {
  extend(FleeFromPlayer, superClass);

  function FleeFromPlayer(c, safeDist) {
    this.safeDist = safeDist;
    FleeFromPlayer.__super__.constructor.apply(this, arguments);
  }

  FleeFromPlayer.prototype.weight = function() {
    var distanceSq;
    distanceSq = require('../util').distanceSq;
    if ((this.creature.canSee(game.player.creature)) && (this.creature.distanceSqTo(game.player.creature)) < (this.safeDist * this.safeDist)) {
      return 100;
    } else {
      return 0;
    }
  };

  FleeFromPlayer.prototype.tick = function() {
    this.creature.moveAwayFrom(game.player.creature);
    return 12;
  };

  return FleeFromPlayer;

})(Personality);

exports.RandomWalk = (function(superClass) {
  extend(RandomWalk, superClass);

  function RandomWalk(c, probability) {
    this.probability = probability != null ? probability : 1;
    RandomWalk.__super__.constructor.apply(this, arguments);
  }

  RandomWalk.prototype.weight = function() {
    return 100;
  };

  RandomWalk.prototype.tick = function() {
    if (random.chance(this.probability)) {
      this.creature.move(random.direction(8));
    }
    return 12;
  };

  return RandomWalk;

})(Personality);

exports.WantItems = (function(superClass) {
  extend(WantItems, superClass);

  function WantItems(c, range1, wantedItems) {
    this.range = range1 != null ? range1 : 1;
    this.wantedItems = wantedItems != null ? wantedItems : null;
    WantItems.__super__.constructor.apply(this, arguments);
  }

  WantItems.prototype.weight = function() {
    var nearest;
    nearest = this.creature.findNearest(this.range, (function(_this) {
      return function(e) {
        return e.type === 'item' && _this.creature.canSee(e);
      };
    })(this));
    if (nearest != null) {
      return 100;
    } else {
      return 0;
    }
  };

  WantItems.prototype.tick = function() {
    var item, itemsHere, nearest;
    nearest = this.creature.findNearest(this.range, (function(_this) {
      return function(e) {
        return e.type === 'item' && _this.creature.canSee(e);
      };
    })(this));
    this.creature.moveTo(nearest);
    itemsHere = this.creature.map.entitiesAt(this.creature.x, this.creature.y, 'item');
    if (itemsHere.length > 0) {
      item = itemsHere[0];
      this.creature.pickup(item);
    }
    return 12;
  };

  return WantItems;

})(Personality);

exports.AttackAllButSpecies = (function(superClass) {
  extend(AttackAllButSpecies, superClass);

  function AttackAllButSpecies(c, species) {
    this.species = species;
    AttackAllButSpecies.__super__.constructor.apply(this, arguments);
  }

  AttackAllButSpecies.prototype.locateTarget = function() {
    return this.creature.findNearest(null, (function(_this) {
      return function(e) {
        return e !== _this.creature && (e.type === 'creature') && (e.species.typeName !== _this.species) && (_this.creature.canSee(e));
      };
    })(this));
  };

  AttackAllButSpecies.prototype.weight = function() {
    if ((this.locateTarget(this.creature)) != null) {
      return 100;
    } else {
      return 0;
    }
  };

  AttackAllButSpecies.prototype.tick = function() {
    var target;
    target = this.locateTarget(this.creature);
    this.creature.moveTo(target);
    if (Math.abs(this.creature.x - target.x) <= 1 && Math.abs(this.creature.y - target.y) <= 1) {
      this.creature.attack(this.creature.directionTo(target));
    }
    return 12;
  };

  return AttackAllButSpecies;

})(Personality);

exports.FleeIfWeak = (function(superClass) {
  extend(FleeIfWeak, superClass);

  function FleeIfWeak() {
    return FleeIfWeak.__super__.constructor.apply(this, arguments);
  }

  FleeIfWeak.prototype.weight = function() {
    if (this.creature.health.percent < 0.2) {
      return 100;
    } else {
      return 0;
    }
  };

  FleeIfWeak.prototype.tick = function() {
    var enemy;
    enemy = this.creature.findNearest(10, function(e) {
      return e.type === 'creature';
    });
    if (enemy != null) {
      this.creature.moveAwayFrom(enemy);
    }
    return 12;
  };

  return FleeIfWeak;

})(Personality);

exports.Gunman = (function(superClass) {
  extend(Gunman, superClass);

  function Gunman() {
    return Gunman.__super__.constructor.apply(this, arguments);
  }

  Gunman.prototype.weight = function() {
    if (this.creature.hasItemInSlot('hand', (function(item) {
      return item.fire != null;
    }))) {
      return 100;
    } else {
      return 0;
    }
  };

  Gunman.prototype.tick = function() {
    var gun, range, target;
    gun = random.sample(this.creature.getItemsForSlot('hand'));
    range = gun.range;
    target = this.creature.findNearest(30, function(e) {
      return e.type === 'creature';
    });
    if (target != null) {
      if ((this.creature.distanceSqTo(target)) > range * range) {
        this.creature.moveTo(target);
        return 12;
      } else {
        return p(gun.fire(this.creature, vectorMath.sub(target, this.creature))).then(function() {
          return 6;
        });
      }
    } else {
      return 12;
    }
  };

  return Gunman;

})(Personality);

exports.Attacker = (function(superClass) {
  extend(Attacker, superClass);

  function Attacker(c, range1) {
    this.range = range1 != null ? range1 : 30;
    Attacker.__super__.constructor.apply(this, arguments);
  }

  Attacker.prototype.weight = function() {
    var target;
    target = this.creature.findNearest(this.range, function(e) {
      return e.type === 'creature';
    });
    if (target != null) {
      return 100;
    } else {
      return 0;
    }
  };

  Attacker.prototype.tick = function() {
    var target;
    target = this.creature.findNearest(this.range, function(e) {
      return e.type === 'creature';
    });
    if (target != null) {
      if (Math.abs(this.creature.x - target.x) <= 1 && Math.abs(this.creature.y - target.y) <= 1) {
        this.creature.attack(this.creature.directionTo(target));
      } else {
        this.creature.moveTo(target);
      }
    }
    return 12;
  };

  return Attacker;

})(Personality);

exports.NoLeaderOutrage = (function(superClass) {
  extend(NoLeaderOutrage, superClass);

  function NoLeaderOutrage(c, range1) {
    this.range = range1 != null ? range1 : 12;
    NoLeaderOutrage.__super__.constructor.apply(this, arguments);
    Object.defineProperty(this, 'target', {
      enumerable: false,
      writable: true
    });
    Object.defineProperty(this, 'monarch', {
      enumerable: false,
      writable: true
    });
  }

  NoLeaderOutrage.prototype.weight = function() {
    this.monarch = this.creature.map.listEntities((function(_this) {
      return function(e) {
        return e.type === 'creature' && e.isGroupLeader(_this.creature);
      };
    })(this))[0];
    if (this.monarch == null) {
      return 100;
    } else {
      return 0;
    }
  };

  NoLeaderOutrage.prototype.tick = function() {
    this.target = this.creature.findNearest(this.range, (function(_this) {
      return function(e) {
        return e.type === 'creature' && !e.belongsToGroup(_this.creature);
      };
    })(this));
    if (this.target != null) {
      if (Math.abs(this.creature.x - this.target.x) <= 1 && Math.abs(this.creature.y - this.target.y) <= 1) {
        this.creature.attack(this.creature.directionTo(this.target));
      } else {
        this.creature.moveTo(this.target);
      }
    } else {
      this.creature.move(random.direction(8));
    }
    return 4;
  };

  return NoLeaderOutrage;

})(Personality);

exports.HateOpposingBees = (function(superClass) {
  extend(HateOpposingBees, superClass);

  function HateOpposingBees(c, range1) {
    this.range = range1 != null ? range1 : 12;
    HateOpposingBees.__super__.constructor.apply(this, arguments);
    Object.defineProperty(this, 'target', {
      enumerable: false,
      writable: true
    });
  }

  HateOpposingBees.prototype.weight = function() {
    this.target = this.creature.findNearest(this.range, (function(_this) {
      return function(e) {
        return e.type === 'creature' && e.species === _this.creature.species && !e.belongsToGroup(_this.creature);
      };
    })(this));
    if (this.target != null) {
      return 100;
    } else {
      return 0;
    }
  };

  HateOpposingBees.prototype.tick = function() {
    if (Math.abs(this.creature.x - this.target.x) <= 1 && Math.abs(this.creature.y - this.target.y) <= 1) {
      this.creature.attack(this.creature.directionTo(this.target));
    } else {
      this.creature.moveTo(this.target);
    }
    return 12;
  };

  return HateOpposingBees;

})(Personality);

exports.FendOffFromLeader = (function(superClass) {
  extend(FendOffFromLeader, superClass);

  function FendOffFromLeader(c, range1) {
    this.range = range1 != null ? range1 : 6;
    FendOffFromLeader.__super__.constructor.apply(this, arguments);
    Object.defineProperty(this, 'target', {
      enumerable: false,
      writable: true
    });
    Object.defineProperty(this, 'monarch', {
      enumerable: false,
      writable: true
    });
  }

  FendOffFromLeader.prototype.weight = function() {
    var weight;
    weight = (function(_this) {
      return function() {
        _this.monarch = _this.creature.map.listEntities(function(e) {
          return e.type === 'creature' && e.isGroupLeader(_this.creature);
        })[0];
        if (_this.monarch == null) {
          return 0;
        }
        _this.target = _this.monarch.findNearest(_this.range, function(e) {
          return e.type === 'creature' && !e.belongsToGroup(_this.creature);
        });
        if (_this.target != null) {
          return 100;
        } else {
          return 0;
        }
      };
    })(this)();
    return weight;
  };

  FendOffFromLeader.prototype.tick = function() {
    if (Math.abs(this.creature.x - this.target.x) <= 1 && Math.abs(this.creature.y - this.target.y) <= 1) {
      this.creature.attack(this.creature.directionTo(this.target));
    } else {
      this.creature.moveTo(this.target, true);
    }
    return 12;
  };

  return FendOffFromLeader;

})(Personality);
