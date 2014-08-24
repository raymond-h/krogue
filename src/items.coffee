_ = require 'lodash'

exports.fromJSON = (json) ->
	if items[json.typeName]?
		_.assign (new items[json.typeName]),
			_.omit json, 'typeName'

	else null

class exports.Item
	symbol: 'I'

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

exports.items = {}
for name, Clazz of (require './definitions/items')
	if Clazz::typeName?
		exports[name] =
		exports.items[Clazz::typeName] = Clazz