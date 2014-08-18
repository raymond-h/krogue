Q = require 'q'
_ = require 'lodash'

game = require './game'

makeHandler = (matcher, done) ->
	(a...) ->
		done a... if matcher a...

charRange = (start, end) ->
	[start.charCodeAt(0)..end.charCodeAt(0)]
	.map (i) -> String.fromCharCode i

exports.listOptions = listOptions = [
	(charRange 'a', 'z')...
	(charRange 'A', 'Z')...
	(charRange '0', '9')...
]

exports.generic = (message, event, matcher, opts) ->
	d = Q.defer()

	handler = makeHandler matcher, (a...) ->
		game.off event, handler
		d.resolve a

	game.on event, handler

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

exports.list = (header, choices, opts) ->
	pressedKey = (key) -> switch
		when 'A' <= key <= 'Z' then "S-#{key.toLowerCase()}"
		else key

	_choices = for v, i in choices
		key: v.key ? listOptions[i]
		name: if _.isString v then v else (v.name ? '???')
		orig: v
		index: i

	mapDisplayed = _.zipObject (
		[(pressedKey v.key), v] for v in _choices
	)

	game.renderer.showList
		header: header
		items: ("#{v.key} - #{v.name}" for v in _choices)

	exports.keys null, ['escape', (_.keys mapDisplayed)...]

	.then (key) ->
		game.renderer.showList null
		return { cancelled: yes } if key is 'escape'

		choice = mapDisplayed[key]
		{
			key: choice.key
			value: choices[choice.index]
			index: choice.index
		}