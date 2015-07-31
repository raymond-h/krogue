var The, _, msg, the;

_ = require('lodash');

The = function(cause) {
  if (_.isString(cause)) {
    return cause;
  } else if (cause.isPlayer()) {
    return 'You';
  } else {
    return "The " + cause.species.name;
  }
};

the = function(cause) {
  if (_.isString(cause)) {
    return cause;
  } else if (cause.isPlayer()) {
    return 'you';
  } else {
    return "the " + cause.species.name;
  }
};

msg = require('./message');

(require('./event-bus')).on('game.creature.hurt', function(target, dmg, cause) {
  var It_was;
  It_was = target.isPlayer() ? 'You were' : "The " + target.species.name + " was";
  return msg(It_was + " hurt for " + dmg + " damage!");
}).on('game.creature.dead', function(target, cause) {
  var It_has;
  It_has = target.isPlayer() ? 'You have' : "The " + target.species.name + " has";
  return msg(It_has + " been killed by " + (the(cause)) + "!");
}).on('game.creature.attack.none', function(attacker, dir) {
  var It_does;
  It_does = attacker.isPlayer() ? 'You do' : "The " + attacker.species.name + " does";
  return msg(It_does + " a cool attack without hitting anything!");
}).on('game.creature.attack.wall', function(attacker, dir) {
  var It_attacks;
  It_attacks = attacker.isPlayer() ? 'You attack' : "The " + attacker.species.name + " attacks";
  return msg(It_attacks + " a wall!");
}).on('game.creature.attack.creature', function(attacker, dir, target) {
  var It_attacks;
  It_attacks = attacker.isPlayer() ? 'You attack' : "The " + attacker.species.name + " attacks";
  return msg(It_attacks + " at " + (the(target)) + "!");
}).on('game.creature.fire', function(firer, item, dir) {
  return msg('BANG!');
}).on('game.creature.fire.empty', function(firer, item, dir) {
  return msg('Click! No ammo...');
}).on('game.creature.fire.hit.none', function(firer, item, dir) {
  return msg('The bullet doesn\'t hit anything...');
}).on('game.creature.fire.hit.wall', function(firer, item, dir, pos) {
  return msg('The bullet strikes a wall...');
}).on('game.creature.fire.hit.creature', function(firer, item, dir, target) {
  return msg("The bullet hits " + (the(target)) + "!");
}).on('game.creature.pickup', function(creature, item) {
  var It_picks;
  It_picks = creature.isPlayer() ? 'You pick' : "The " + creature.species.name + " picks";
  return msg(It_picks + " up the " + item.name + ".");
}).on('game.creature.drop', function(creature, item) {
  var It_drops;
  It_drops = creature.isPlayer() ? 'You drop' : "The " + creature.species.name + " drops";
  return msg(It_drops + " the " + item.name + ".");
}).on('game.creature.equip', function(equipper, item) {
  var It_equips;
  It_equips = equipper.isPlayer() ? 'You equip' : "The " + equipper.species.name + " equips";
  return msg(It_equips + " the " + item.name + ".");
}).on('game.creature.unequip', function(equipper, item) {
  var It_puts;
  It_puts = equipper.isPlayer() ? 'You put' : "The " + equipper.species.name + " puts";
  return msg(It_puts + " away the " + item.name + ".");
});
