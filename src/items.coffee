_ = require 'lodash'

exports.fromJSON = (json) ->
	if items[json.typeName]?
		_.assign (new items[json.typeName]),
			_.omit json, 'typeName'

	else null

Item = class exports.Item
	symbol: 'I'

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

itemsArray = [
	class exports.PeculiarObject extends Item
		typeName: 'peculiar-object'

		name: 'peculiar object'
		symbol: 'O'

	class exports.Gun extends Item
		typeName: 'gun'

		name: 'gun'
		symbol: '/'
]

exports.items = items = {}
for Clazz in itemsArray
	exports.items[Clazz::typeName] = Clazz