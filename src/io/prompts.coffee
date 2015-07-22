Promise = require 'bluebird'
_ = require 'lodash'

eventBus = require '../event-bus'

charRange = (start, end) ->
	[start.charCodeAt(0)..end.charCodeAt(0)]
	.map (i) -> String.fromCharCode i

module.exports = class Prompts
	listOptions: [
		(charRange 'a', 'z')...
		(charRange 'A', 'Z')...
		(charRange '0', '9')...
	]

	constructor: (@game) ->

	generic: (message, event, matcher, opts) ->
		new Promise (resolve, reject) =>
			event = [].concat event

			handler = (a...) ->
				if matcher @event, a...
					(eventBus.off e, handler) for e in event

					resolve [@event, a...]

			(eventBus.on e, handler) for e in event

			@game.renderer.setPromptMessage message

	keys: (message, keys, opts) ->
		{showKeys, shownKeys, separator} = _.defaults {}, opts,
			showKeys: yes
			separator: ','

		if message? and showKeys
			message = "#{message} [#{(shownKeys ? keys).join separator}]"

		@generic message, 'key.*',
			(event, ch, key) -> key.full in keys
		, opts

		.then ([event, ch, key]) -> key.full

	actions: (message, actions, opts) ->
		{showActions, shownActions, separator, cancelable} =
			_.defaults {}, opts,
				showActions: yes
				separator: ','
				cancelable: no

		if message? and showActions
			message = "#{message} [#{(shownActions ? actions).join separator}]"

		@generic message, ['key.escape', 'action.**'],
			(event, action, params...) ->
				return yes if cancelable and event is 'key.escape'

				action in actions
		, opts

		.then ([event, a...]) ->
			if event is 'key.escape' then null
			else a

	yesNo: (message, opts = {}) ->
		opts.shownKeys ?= ['y', 'n']
		opts.separator ?= ''

		choices = ['y', 'n']
		if opts.cancelable
			choices.push 'escape'

		@keys message, choices, opts
		.then (reply) ->
			switch reply
				when 'escape' then null
				when 'y' then yes
				else no

	direction: (message, opts = {}) ->
		opts.shownActions ?= ['direction','escape'] if opts.cancelable

		@actions message, ['direction'], opts

		.then (reply) ->
			return null if not reply?

			reply[1] # first param

	pressedKey: (key) -> switch
		when 'A' <= key <= 'Z' then "S-#{key.toLowerCase()}"
		else key
