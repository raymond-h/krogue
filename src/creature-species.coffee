exports.fromJSON = (json) ->
	# when converting species to JSON
	# only the type name is saved as string
	# so 'json' in this case is simply a string
	new species[json]

class exports.Species
	equipSlots: []

	toJSON: ->
		# species inst. contain no data themselves
		# we can just save the type name directly
		@typeName

exports.species = {}
for name, Clazz of (require './definitions/creature-species')
	if Clazz::typeName?
		exports[name] =
		exports.species[Clazz::typeName] = Clazz