{Creature} = require './entities'

exports.Creature = Creature

exports.fromJSON = (json) ->
	(new Creature).loadFromJSON json

CreatureSpecies = class exports.CreatureSpecies
	symbol: 'S'

class exports.StrangeGoo extends CreatureSpecies
	symbol: 'g'

class exports.Human extends CreatureSpecies
	symbol: '@'