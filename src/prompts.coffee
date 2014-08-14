Q = require 'q'
_ = require 'lodash'

exports.keys = (message, keys, opts) ->
	{showKeys, separator} = _.defaults {}, opts,
		showKeys: yes
		separator: ','

	game = require './game'
	d = Q.defer()

	if showKeys
		message = "#{message} [#{keys.join separator}]"

	keyHandler = (ch, key) ->
		if key.full in keys
			game.events.off 'key.*', keyHandler
			d.resolve key.full

	game.events.on 'key.*', keyHandler

	game.message message
	game.renderer.showMoreLogs()

	d.promise

exports.yesNo = (message, opts = {}) ->
	opts.separator ?= ''
	exports.keys message, ['y', 'n'], opts

	.then (reply) -> reply is 'y'

exports.direction = (message, opts) ->
	exports.keys message, ['up', 'down', 'left', 'right'], opts

	.then (reply) -> reply