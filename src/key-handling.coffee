_ = require 'lodash'
direction = require './direction'
{snapToRange} = require './util'

bindings = require '../key-bindings.json'

fixDirection = (dir) ->
	o = direction.parse dir
	o = [ (snapToRange -1, o[0], 1), (snapToRange -1, o[1], 1) ]
	direction.asString o

module.exports = exports = (game) ->
	game.events

	.on 'key.*', (ch, key) ->
		action = bindings[key.full]

		if action?
			parts = action.split('.')

			if parts[0] is 'direction' then parts[1] = fixDirection parts[1]

			game.events.emit "action.#{parts.join '.'}", parts...

exports.bindings = bindings