var _, creatureStat, gunDamage, itemSlotUse, levelFromXp, meleeDamage, random, stat, xpForLevel;

_ = require('lodash');

random = require('./random');

meleeDamage = function(subject, item, target) {
  var dmg, dmgDev, meleeDmg;
  dmgDev = (-0.1107 * (subject.calc('accuracy', item)) + 3.32881) * 4;
  meleeDmg = random.gaussian(subject.calc('attack', item), dmgDev)[0];
  dmg = Math.round(meleeDmg - (target.calc('defense')));
  return Math.max(0, dmg);
};

gunDamage = function(subject, gun, target) {
  var dmg, dmgDev, gunDmg;
  dmgDev = (-0.1107 * (subject.calc('accuracy', gun)) + 3.32881) * 4;
  gunDmg = random.gaussian(gun.damage, dmgDev)[0];
  dmg = Math.round(gunDmg - (target.calc('defense')));
  return Math.max(0, dmg);
};

xpForLevel = function(level) {
  return (level - 1) * 100;
};

levelFromXp = _.memoize(function(xp) {
  var level;
  level = 1;
  while ((xpForLevel(level + 1)) <= xp) {
    level++;
  }
  return level;
});

itemSlotUse = function(creature, item) {
  var cs, iw, ref;
  cs = creature.calc('strength');
  iw = (ref = item.weight) != null ? ref : 0;
  return Math.max(1, Math.round(0.148773 * iw * Math.pow(Math.E, -0.0241275 * (cs - 15) / 3)));
};

creatureStat = function(creature, stat) {
  return 15 + 3 * creature.level;
};

stat = {
  health: function(subject) {
    return subject.calc('endurance');
  },
  attack: function(subject, arg) {
    var damage;
    damage = (arg != null ? arg : {}).damage;
    return (subject.calc('strength')) + (damage != null ? damage : 0);
  },
  defense: function(subject) {
    var totalArmor;
    totalArmor = _.chain(subject.equipment).pluck('armor').reduce((function(sum, v) {
      return sum + (v != null ? v : 0);
    }), 0).value();
    return (subject.calc('endurance')) / 3 + totalArmor;
  },
  speed: function(subject) {
    return Math.max(1, (subject.calc('agility')) / 3 - stat.excessWeight(subject));
  },
  accuracy: function(subject, arg) {
    var accuracy;
    accuracy = (arg != null ? arg : {}).accuracy;
    return ((subject.calc('strength')) + (subject.calc('agility'))) * (accuracy != null ? accuracy : 1);
  },
  maxWeight: function(subject) {
    return subject.calc('strength');
  },
  weight: function(subject, include) {
    var eqpWeight, equips, invWeight, inventory, itself, subjWeight, weightOf;
    if (include == null) {
      include = {};
    }
    _.defaults(include, {
      itself: true,
      inventory: true,
      equips: true
    });
    itself = include.itself, inventory = include.inventory, equips = include.equips;
    weightOf = function(i) {
      var ref;
      return (ref = i.weight) != null ? ref : 0;
    };
    invWeight = inventory ? subject.inventory.map(function(item) {
      return weightOf(item);
    }).reduce((function(p, c) {
      return p + c;
    }), 0) : 0;
    eqpWeight = equips ? subject.equipment.map(function(item) {
      return weightOf(item);
    }).reduce((function(p, c) {
      return p + c;
    }), 0) : 0;
    subjWeight = itself ? weightOf(subject) : 0;
    return subjWeight + eqpWeight + invWeight;
  },
  excessWeight: function(subject) {
    return Math.max(0, (subject.calc('weight', {
      itself: false
    })) - (subject.calc('maxWeight')));
  }
};

module.exports = {
  meleeDamage: meleeDamage,
  gunDamage: gunDamage,
  itemSlotUse: itemSlotUse,
  xpForLevel: xpForLevel,
  levelFromXp: levelFromXp,
  creatureStat: creatureStat,
  stat: stat
};
