_ = require 'lodash'

exports.fromJSON = (json) ->
	if personalities[json.typeName]?
		_.assign (new personalities[json.typeName]),
			_.omit json, 'typeName'

	else null

class exports.Personality
	constructor: ->
		@weightMultiplier = 1

	withMultiplier: (@weightMultiplier) -> this

	weight: (creature) -> 0

	tick: (creature) -> 0

	toJSON: ->
		json = _.pick @, (v, k, o) -> _.has o, k
		json.typeName = @typeName
		json

exports.personalities = {}
for name, Clazz of (require './definitions/personalities')
	if Clazz::typeName?
		exports[name] =
		exports.personalities[Clazz::typeName] = Clazz