_ = require 'lodash'

exports.fromJSON = (json) ->
	_.assign (new items[json.typeName]),
		_.omit json, 'typeName'

Item = class exports.Item
	symbol: 'I'

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

exports.items = items =
	'peculiar-object': class PeculiarObject extends Item
		symbol: 'O'

for typeName, Clazz of items
	Clazz::typeName ?= typeName