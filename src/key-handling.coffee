_ = require 'lodash'
direction = require './direction'

bindings = require '../key-bindings.json'

module.exports = exports = (game) ->
	game.on 'key.*', (ch, key) ->
		action = bindings[key.full ? key.name]

		if action?
			parts = action.split('.')

			if parts[0] is 'direction'
				parts[1] = direction.normalize parts[1], 1

			game.emit "action.#{parts.join '.'}", parts...

exports.bindings = bindings