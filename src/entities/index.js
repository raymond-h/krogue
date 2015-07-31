var Creature, entity;

entity = require('./entity');

Creature = require('./creature');

module.exports = {
  Creature: Creature,
  Entity: entity.Entity,
  Stairs: entity.Stairs,
  MapItem: entity.MapItem
};
