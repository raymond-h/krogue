exports.fromJSON = (json) ->
	# when converting species to JSON
	# only the type name is saved as string
	# so 'json' in this case is simply a string
	new species[json]

Species = class exports.Species
	equipSlots: []

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

		name: 'strange goo'
		symbol: 'g'

	class exports.Human extends Species
		typeName: 'human'

		name: 'human'
		symbol: '@'
		equipSlots: [
			'head'
			'right hand', 'left hand'
		]

	class exports.ViolentDonkey extends Species
		typeName: 'violent-donkey'

		name: 'violent donkey'
		symbol: 'h'
]

exports.species = species = {}
for Clazz in speciesArray
	exports.species[Clazz::typeName] = Clazz