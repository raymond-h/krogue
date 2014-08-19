Q = require 'q'
_ = require 'lodash'

game = require './game'
{whilst} = require './util'

charRange = (start, end) ->
	[start.charCodeAt(0)..end.charCodeAt(0)]
	.map (i) -> String.fromCharCode i

pressedKey = (key) -> switch
	when 'A' <= key <= 'Z' then "S-#{key.toLowerCase()}"
	else key

exports.listOptions = listOptions = [
	(charRange 'a', 'z')...
	(charRange 'A', 'Z')...
	(charRange '0', '9')...
]

exports.generic = (message, event, matcher, opts) ->
	d = Q.defer()
	event = [].concat event

	handler = (a...) ->
		if matcher @event, a...
			(game.off e, handler) for e in event

			d.resolve [@event, a...]

	(game.on e, handler) for e in event

	if message?
		game.message message
		game.renderer.showMoreLogs()

	d.promise

exports.keys = (message, keys, opts) ->
	{showKeys, shownKeys, separator} = _.defaults {}, opts,
		showKeys: yes
		separator: ','

	if message? and showKeys
		message = "#{message} [#{(shownKeys ? keys).join separator}]"

	exports.generic message, 'key.*',
		(event, ch, key) -> key.full in keys
	, opts

	.then ([event, ch, key]) -> key.full

exports.actions = (message, actions, opts) ->
	{showActions, shownActions, separator, cancelable} =
		_.defaults {}, opts,
			showActions: yes
			separator: ','
			cancelable: no

	if message? and showActions
		message = "#{message} [#{(shownActions ? actions).join separator}]"

	exports.generic message, ['key.escape', 'action.**'],
		(event, action, params...) ->
			return yes if cancelable and event is 'key.escape'

			action in actions
	, opts

	.then ([event, a...]) ->
		if event is 'key.escape' then null
		else a

exports.yesNo = (message, opts = {}) ->
	opts.shownKeys ?= ['y', 'n']
	opts.separator ?= ''

	choices = ['y', 'n']
	if opts.cancelable
		choices.push 'escape'

	exports.keys message, choices, opts
	.then (reply) ->
		switch reply
			when 'escape' then null
			when 'y' then yes
			else no

exports.direction = (message, opts = {}) ->
	opts.shownActions ?= ['direction','escape'] if opts.cancelable

	exports.actions message, ['direction'], opts

	.then (reply) ->
		return null if not reply?

		reply[1] # first param

exports.list = (header, choices, opts) ->
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
		return null if key is 'escape'

		choice = mapDisplayed[key]
		{
			key: choice.key
			value: choices[choice.index]
			index: choice.index
		}

exports.multichoiceList = (header, choices, opts) ->
	_choices = for v, i in choices
		key: v.key ? listOptions[i]
		name: if _.isString v then v else (v.name ? '???')
		orig: v
		index: i
		checked: no

	mapDisplayed = _.zipObject (
		[(pressedKey v.key), v] for v in _choices
	)

	updateList = ->
		game.renderer.showList
			header: header
			items: for v in _choices
				"#{v.key} #{if v.checked then '+' else '-'} #{v.name}"

	updateList()

	done = no
	whilst (-> not done),
		->
			exports.keys null, ['escape', 'return', (_.keys mapDisplayed)...]

			.then (key) ->
				switch key
					when 'return' then done = yes
					when 'escape' then done = 'cancel'

					else
						choice = mapDisplayed[key]
						choice.checked = not choice.checked

				updateList()

	.then ->
		game.renderer.showList null
		return null if done is 'cancel'

		for choice in _choices when choice.checked
			{
				key: choice.key
				value: choices[choice.index]
				index: choice.index
			}