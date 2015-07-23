_ = require 'lodash'
direction = require 'rl-directions'

bindings = require '../key-bindings.json'

eventBus = require './event-bus'

eventBus.on 'key.*', (ch, key) ->
	action = bindings[key.full] ? bindings[key.name]

	if action?
		parts = action.split('.')

		if parts[0] is 'direction'
			parts[1] = direction.normalize parts[1], 1

		eventBus.emit "action.#{parts.join '.'}", parts...

exports.bindings = bindings
