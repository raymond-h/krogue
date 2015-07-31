var Creature, itemGen, items, personality, random, species;

random = require('../random');

personality = require('../definitions/personalities');

species = require('../definitions/creature-species');

items = require('../definitions/items');

Creature = require('../entities').Creature;

itemGen = require('./items');

exports.generateStartingPlayer = function(x, y) {
  var c, gun, i;
  c = new Creature({
    x: x,
    y: y,
    species: species.human
  });
  gun = itemGen.generateStartingGun();
  c.equip(gun, true);
  c.inventory = (function() {
    var j, results;
    results = [];
    for (i = j = 1; j <= 5; i = ++j) {
      results.push(new items.PokeBall(random.sample(['normal', 'great', 'ultra', 'master'])));
    }
    return results;
  })();
  c.inventory.push(new items.BulletPack(new items.Bullet('medium'), 20));
  c.inventory.push(new items.BulletPack(new items.Bullet('medium'), 5));
  return c;
};

exports.generateStrangeGoo = function(x, y) {
  var c, ref, ref1;
  c = new Creature({
    x: x,
    y: y
  });
  if (random.chance(0.50)) {
    (ref = c.personalities).push.apply(ref, [new personality.FleeFromPlayer(c, 5), (new personality.RandomWalk(c)).withMultiplier(0.5)]);
  } else {
    (ref1 = c.personalities).push.apply(ref1, [new personality.FleeFromPlayer(c, 5), (new personality.WantItems(c, 15)).withMultiplier(0.5)]);
  }
  return c;
};

exports.generateViolentDonkey = function(x, y) {
  var c, ref;
  c = new Creature({
    x: x,
    y: y,
    species: species.violentDonkey
  });
  (ref = c.personalities).push.apply(ref, [new personality.AttackAllButSpecies(c, c.species.typeName)]);
  return c;
};

exports.generateTinyAlien = function(x, y) {
  var c, ref;
  c = new Creature({
    x: x,
    y: y,
    species: species.tinyAlien
  });
  (ref = c.personalities).push.apply(ref, [(new personality.FleeIfWeak(c)).withMultiplier(10), new personality.Attacker(c)]);
  if (random.chance(0.5)) {
    c.equip(itemGen.generateGun());
    c.personalities.push((new personality.Gunman(c)).withMultiplier(2));
  }
  return c;
};

exports.generateSpaceAnemone = function(x, y) {
  var c, ref;
  c = new Creature({
    x: x,
    y: y,
    species: species.spaceAnemone
  });
  (ref = c.personalities).push.apply(ref, [new personality.RandomWalk(c), (new personality.Attacker(c, 6)).withMultiplier(2)]);
  return c;
};

exports.generateSpaceBee = function(x, y, arg) {
  var c, group, monarch, ref, ref1, ref2;
  ref = arg != null ? arg : {}, monarch = ref.monarch, group = ref.group;
  if (monarch == null) {
    monarch = false;
  }
  if (group == null) {
    group = null;
  }
  c = new Creature({
    x: x,
    y: y,
    species: monarch ? species.spaceBeeMonarch : species.spaceBee
  });
  c.group = group;
  if (!monarch) {
    (ref1 = c.personalities).push.apply(ref1, [(new personality.NoLeaderOutrage(c, 20)).withMultiplier(10), (new personality.FendOffFromLeader(c)).withMultiplier(6), (new personality.HateOpposingBees(c)).withMultiplier(3), new personality.RandomWalk(c)]);
  } else {
    c.leader = true;
    (ref2 = c.personalities).push.apply(ref2, [new personality.RandomWalk(c, 0.2)]);
  }
  return c;
};

exports.generateHaithera = function(x, y) {
  var c, ref;
  c = new Creature({
    x: x,
    y: y,
    species: species.haithera
  });
  (ref = c.personalities).push.apply(ref, [(new personality.Attacker(c, 10)).withMultiplier(2), new personality.RandomWalk(c)]);
  return c;
};
