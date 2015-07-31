var Clazz, Species, _, className, classes, equipSlotNum, humanoidSlots, makeName, quadrupedSlots, skills,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

_ = require('lodash');

skills = require('./skills');

Species = exports.Species = (function() {
  function Species() {}

  Species.prototype.equipSlotNum = {
    head: 1,
    hand: 0,
    body: 1,
    foot: 0
  };

  Species.prototype.skills = function() {
    return [];
  };

  return Species;

})();

equipSlotNum = function(Clazz, slots) {
  return Clazz.prototype.equipSlotNum = _.assign({}, Species.prototype.equipSlotNum, slots);
};

exports._equipSlots = ['head', 'hand', 'body', 'foot'];

humanoidSlots = {
  hand: 2,
  foot: 2
};

quadrupedSlots = {
  hand: 0,
  foot: 4
};

exports.classes = classes = {};

classes.StrangeGoo = (function(superClass) {
  extend(StrangeGoo, superClass);

  function StrangeGoo() {
    return StrangeGoo.__super__.constructor.apply(this, arguments);
  }

  StrangeGoo.prototype.name = 'strange goo';

  StrangeGoo.prototype.modifyStat = function(creature, stat, name) {
    if (name === 'agility') {
      return stat / 3;
    }
  };

  return StrangeGoo;

})(Species);

classes.Human = (function(superClass) {
  extend(Human, superClass);

  function Human() {
    return Human.__super__.constructor.apply(this, arguments);
  }

  Human.prototype.name = 'human';

  Human.prototype.weight = 60;

  equipSlotNum(Human, humanoidSlots);

  Human.prototype.skills = function() {
    return slice.call(Human.__super__.skills.apply(this, arguments)).concat([new skills.SenseLasagna], [new skills.TentacleWhip], [new skills.Blink]);
  };

  Human.prototype.modifyStat = function(creature, stat, name) {
    if (name === 'agility' || name === 'strength' || name === 'endurance') {
      return stat * 20;
    } else {
      return stat;
    }
  };

  return Human;

})(Species);

classes.ViolentDonkey = (function(superClass) {
  extend(ViolentDonkey, superClass);

  function ViolentDonkey() {
    return ViolentDonkey.__super__.constructor.apply(this, arguments);
  }

  ViolentDonkey.prototype.name = 'violent donkey';

  ViolentDonkey.prototype.weight = 120;

  equipSlotNum(ViolentDonkey, quadrupedSlots);

  return ViolentDonkey;

})(Species);

classes.TinyAlien = (function(superClass) {
  extend(TinyAlien, superClass);

  function TinyAlien() {
    return TinyAlien.__super__.constructor.apply(this, arguments);
  }

  TinyAlien.prototype.name = 'tiny alien';

  TinyAlien.prototype.weight = 20;

  equipSlotNum(TinyAlien, humanoidSlots);

  return TinyAlien;

})(Species);

classes.SpaceAnemone = (function(superClass) {
  extend(SpaceAnemone, superClass);

  function SpaceAnemone() {
    return SpaceAnemone.__super__.constructor.apply(this, arguments);
  }

  SpaceAnemone.prototype.name = 'space anemone';

  SpaceAnemone.prototype.weight = 300;

  equipSlotNum(SpaceAnemone, {
    head: 0,
    hand: 55
  });

  SpaceAnemone.prototype.modifyStat = function(creature, stat, name) {
    switch (name) {
      case 'strength':
        return stat * 4.5;
      case 'agility':
        return stat / 2.0;
      default:
        return stat;
    }
  };

  return SpaceAnemone;

})(Species);

classes.SpaceBee = (function(superClass) {
  extend(SpaceBee, superClass);

  function SpaceBee() {
    return SpaceBee.__super__.constructor.apply(this, arguments);
  }

  SpaceBee.prototype.name = 'space bee';

  SpaceBee.prototype.weight = 1 / 10000;

  equipSlotNum(SpaceBee, {
    hand: 0,
    foot: 6
  });

  SpaceBee.prototype.modifyStat = function(creature, stat, name) {
    switch (name) {
      case 'strength':
        return stat * 0.01;
      case 'agility':
        return stat * 4;
      case 'endurance':
        return stat * 0.01;
      default:
        return stat;
    }
  };

  return SpaceBee;

})(Species);

classes.SpaceBeeMonarch = (function(superClass) {
  extend(SpaceBeeMonarch, superClass);

  function SpaceBeeMonarch() {
    return SpaceBeeMonarch.__super__.constructor.apply(this, arguments);
  }

  SpaceBeeMonarch.prototype.name = 'space bee monarch';

  SpaceBeeMonarch.prototype.weight = 2 / 10000;

  return SpaceBeeMonarch;

})(classes.SpaceBee);

classes.Haithera = (function(superClass) {
  extend(Haithera, superClass);

  function Haithera() {
    return Haithera.__super__.constructor.apply(this, arguments);
  }

  Haithera.prototype.name = 'haithera';

  Haithera.prototype.weight = 400;

  return Haithera;

})(Species);

makeName = function(className) {
  return className[0].toLowerCase() + className.slice(1);
};

for (className in classes) {
  Clazz = classes[className];
  exports[makeName(className)] = new Clazz;
}
