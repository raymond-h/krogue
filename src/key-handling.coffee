_ = require 'lodash'
direction = require './direction'

bindings = require '../key-bindings.json'

module.exports = exports = (game) ->
	game.events

	.on 'key.*', (ch, key) ->
		action = bindings[key.full]

		if action?
			parts = action.split('.')

			if parts[0] is 'direction'
				parts[1] = direction.normalize parts[1], 1

			game.events.emit "action.#{parts.join '.'}", parts...

exports.bindings = bindings