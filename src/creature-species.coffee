{Creature} = require './entities'
{dasherize} = require './util'

exports.Creature = Creature

exports.creatureFromJSON = (json) ->
	(new Creature).loadFromJSON json

exports.species = species = {}

exports.add = add = (Clazz) ->
	Clazz::typeName ?= dasherize Clazz.name

	species[Clazz::typeName] = Clazz

exports.fromJSON = (json) ->
	# when converting species to JSON, only the name is saved as string
	# so 'json' in this case is simply a string
	new species[json]

CreatureSpecies = class exports.CreatureSpecies
	toJSON: ->
		# species inst. contain no data themselves
		# we can just save the name directly
		@typeName

###
Species
###
add class exports.StrangeGoo extends CreatureSpecies
	symbol: 'g'

add class exports.Human extends CreatureSpecies
	symbol: '@'