_ = require 'lodash'

{Player, Dummy, FastDummy} = require './creatures'

exports.type = entityTypes = {}

exports.add = add = (clazz) ->
	name = _.result clazz::, 'type'

	entityTypes[name] = clazz

exports.fromJSON = (game, json) ->
	Clazz = entityTypes[json.type]

	if Clazz?
		e = new Clazz game
		e.loadFromJSON json
		e

	else null

add Player
add Dummy
add FastDummy