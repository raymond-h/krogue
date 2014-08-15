Q = require 'q'
_ = require 'lodash'

makeHandler = (matcher, done) ->
	(a...) ->
		done a... if matcher a...

exports.generic = (message, event, matcher, opts) ->
	game = require './game'
	d = Q.defer()

	handler = makeHandler matcher, (a...) ->
		game.events.off event, handler
		d.resolve a

	game.events.on event, handler

	if message?
		game.message message
		game.renderer.showMoreLogs()

	d.promise

exports.keys = (message, keys, opts) ->
	{showKeys, separator} = _.defaults {}, opts,
		showKeys: yes
		separator: ','

	if message? and showKeys
		message = "#{message} [#{keys.join separator}]"

	exports.generic message, 'key.*',
		(ch, key) -> key.full in keys

	.then ([ch, key]) -> key.full

exports.actions = (message, actions, opts) ->
	{showActions, shownActions, separator} =
		_.defaults {}, opts,
			showActions: yes
			separator: ','

	if message? and showActions
		message = "#{message} [#{(shownActions ? actions).join separator}]"

	exports.generic message, 'action.**',
		(action, params...) -> action in actions

exports.yesNo = (message, opts = {}) ->
	opts.separator ?= ''
	exports.keys message, ['y', 'n'], opts

	.then (reply) -> reply is 'y'

exports.direction = (message, opts) ->
	exports.actions message, ['direction'], opts

	.then ([action, params...]) -> params[0]