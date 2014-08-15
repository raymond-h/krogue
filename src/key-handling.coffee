bindings = require '../key-bindings.json'

(require 'winston').info 'Loaded key bindings:', (require 'util').inspect bindings

module.exports = exports = (game) ->
	game.events

	.on 'key.*', (ch, key) ->
		action = bindings[key.full]

		if action?
			game.events.emit "action.#{action}", action.split('.')...

exports.bindings = bindings