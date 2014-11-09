Q = require 'q'
_ = require 'lodash'

_.extend exports, require './common-prompts'
{pressedKey, listOptions} = exports

game = require '../game'
{whilst, snapToRange} = require '../util'

# On choice taken: {key, value, index}
# On cancel: null
exports.list = (header, choices, opts) ->
	deferred = Q.defer()

	_choices = for v, i in choices
		key: v?.key ? listOptions[i]
		name: if _.isString v then v else (v.name ? '???')
		orig: v
		index: i

	choicePicked = (index) ->
		game.renderer.hideMenu()

		choice = _choices[index]
		deferred.resolve
			key: choice.key
			value: choices[index]
			index: index

	cancel = ->
		game.renderer.hideMenu()
		deferred.resolve null

	items = ("#{v.key}. #{v.name}" for v in _choices)

	game.renderer.showSingleChoiceMenu header, items,
		onChoice: choicePicked
		onCancel: cancel

	mapDisplayed = _.zipObject (
		[(pressedKey v.key), v.index] for v in _choices
	)

	exports.keys null, ['escape', (_.keys mapDisplayed)...]
	.then (key) ->
		return cancel() if key is 'escape'
		choicePicked mapDisplayed[key]

	deferred.promise

# On done taken: [{key, value, index}, ...]
# On cancel: null
exports.multichoiceList = (header, choices, opts) ->
	stopped = no

	deferred = Q.defer()

	_choices = for v, i in choices
		key: v.key ? listOptions[i]
		name: if _.isString v then v else (v.name ? '???')
		orig: v
		index: i
		checked: no

	done = (indices) ->
		stopped = yes
		game.renderer.hideMenu()

		finalChoices = indices.map (index) ->
			choice = _choices[index]

			key: choice.key
			value: choices[index]
			index: index

		deferred.resolve finalChoices

	cancel = ->
		stopped = yes
		game.renderer.hideMenu()
		deferred.resolve null

	items = ("#{v.key}. #{v.name}" for v in _choices)

	[updateChecked, callbackDone] =
		game.renderer.showMultiChoiceMenu header, items,
			onDone: done
			onCancel: cancel

	mapDisplayed = _.zipObject (
		[(pressedKey v.key), v.index] for v in _choices
	)

	whilst (-> not stopped),
		->
			exports.keys null, ['escape', 'enter', (_.keys mapDisplayed)...]
			.then (key) ->
				return if stopped
				return cancel() if key is 'escape'
				return callbackDone() if key is 'enter'

				updateChecked mapDisplayed[key]

	deferred.promise

direction = require '../direction'
vectorMath = require '../vector-math'

exports.position = (message, opts = {}) ->
	if message?
		game.message message
		game.renderer.showMoreLogs()

	pos = opts.default ? {x: 0, y: 0}

	cancelled = no
	done = no
	whilst (-> not done),
		->
			game.renderer.cursor = pos
			game.renderer.invalidate()

			exports.generic null, ['key.escape', 'key.enter', 'action.**'],
				(event, action, params...) ->
					(event in ['key.escape', 'key.enter']) or action is 'direction'

			.then ([event, action, dir]) ->
				switch event
					when 'key.escape'
						done = yes
						cancelled = yes

					when 'key.enter' then done = yes

					else
						pos = vectorMath.add pos, direction.parse dir

						pos.x = snapToRange 0, pos.x, game.currentMap.w
						pos.y = snapToRange 0, pos.y, game.currentMap.h

	.then ->
		game.renderer.cursor = null
		game.renderer.invalidate()

		if not cancelled then pos
		else null