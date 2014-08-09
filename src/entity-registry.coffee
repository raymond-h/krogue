_ = require 'lodash'

{Human, Dummy, FastDummy} = require './creatures'

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

add Human
add Dummy
add FastDummy