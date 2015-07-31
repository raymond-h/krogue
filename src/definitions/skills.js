var Promise, Skill, _, calc, direction, game, log, message, prompts, vectorMath,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

_ = require('lodash');

Promise = require('bluebird');

game = require('../game');

log = require('../log');

message = require('../message');

prompts = game.prompts;

direction = require('rl-directions');

vectorMath = require('../vector-math');

calc = require('../calc');

Skill = exports.Skill = (function() {
  function Skill() {}

  Skill.prototype.name = 'skill';

  return Skill;

})();

exports.TentacleWhip = (function(superClass) {
  extend(TentacleWhip, superClass);

  function TentacleWhip() {
    return TentacleWhip.__super__.constructor.apply(this, arguments);
  }

  TentacleWhip.prototype.name = 'tentacle whip';

  TentacleWhip.prototype.askParams = function(creature) {
    return Promise.all([
      prompts.position('Whip towards where?', {
        "default": creature
      })
    ]).then(function(arg) {
      var position;
      position = arg[0];
      return {
        position: position
      };
    });
  };

  TentacleWhip.prototype.use = function(creature, params) {
    console.log('whip:', params);
    return 12;
  };

  return TentacleWhip;

})(Skill);

exports.SenseLasagna = (function(superClass) {
  extend(SenseLasagna, superClass);

  function SenseLasagna() {
    return SenseLasagna.__super__.constructor.apply(this, arguments);
  }

  SenseLasagna.prototype.name = 'sense lasagna';

  SenseLasagna.prototype.use = function(creature) {
    return message("You feel no presence of any lasagna aura in your vicinity. Disappointing.");
  };

  return SenseLasagna;

})(Skill);

exports.Blink = (function(superClass) {
  extend(Blink, superClass);

  function Blink() {
    return Blink.__super__.constructor.apply(this, arguments);
  }

  Blink.prototype.name = 'blink';

  Blink.prototype.askParams = function(creature) {
    return Promise["try"](function() {
      return prompts.position('Teleport where?', {
        "default": creature
      });
    }).then(function(position) {
      if (!creature.canSee(position)) {
        return prompts.yesNo('This is a terrible idea. Do it anyway?').then(function(doIt) {
          return [position, doIt];
        });
      } else {
        return Promise.resolve([position, true]);
      }
    }).then(function(arg) {
      var doIt, position;
      position = arg[0], doIt = arg[1];
      return {
        position: position,
        doIt: doIt
      };
    });
  };

  Blink.prototype.use = function(creature, arg) {
    var doIt, position;
    position = arg.position, doIt = arg.doIt;
    if (!doIt) {
      return message("Cancelled blinking.");
    } else {
      message("*BZOOM*");
      creature.setPos(position);
      return 2;
    }
  };

  return Blink;

})(Skill);
