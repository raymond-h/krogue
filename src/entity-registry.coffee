_ = require 'lodash'

{Player, Dummy, FastDummy} = require './creatures'

exports.type = entityTypes = {}

exports.add = add = (clazz) ->
	name = _.result clazz::, 'type'

	entityTypes[name] = clazz

add Player
add Dummy
add FastDummy