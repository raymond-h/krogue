{dasherize} = require './util'

exports.Creature = Creature = (require './entities').Creature

exports.creatureFromJSON = (json) ->
	(new Creature).loadFromJSON json

exports.fromJSON = (json) ->
	# when converting species to JSON
	# only the type name is saved as string
	# so 'json' in this case is simply a string
	new species[json]

Species = class exports.Species
	toJSON: ->
		# species inst. contain no data themselves
		# we can just save the type name directly
		@typeName

###
Species
###
exports.species = species =
	'strange-goo': class exports.StrangeGoo extends Species
		symbol: 'g'

	'human': class exports.Human extends Species
		symbol: '@'

for typeName, Clazz of species
	Clazz::typeName ?= typeName