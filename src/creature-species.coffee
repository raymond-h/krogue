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
speciesArray = [
	class exports.StrangeGoo extends Species
		typeName: 'strange-goo'
		symbol: 'g'

	class exports.Human extends Species
		typeName: 'human'
		symbol: '@'
]

exports.species = species = {}
for Clazz in speciesArray
	exports.species[Clazz::typeName] = Clazz