_ = require 'lodash'

{Creature} = require './creatures'

exports.type = entityTypes = {}

exports.add = add = (clazz) ->
	name = _.result clazz::, 'type'

	entityTypes[name] = clazz

exports.fromJSON = (json) ->
	Clazz = entityTypes[json.type]

	if Clazz?
		e = new Clazz
		e.loadFromJSON json
		e

	else null

add Creature