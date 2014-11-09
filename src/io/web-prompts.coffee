Q = require 'q'
_ = require 'lodash'

_.extend exports, require './common-prompts'
{pressedKey, listOptions} = exports

game = require '../game'
{whilst} = require '../util'

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

	items = ("#{v.key} - #{v.name}" for v in _choices)

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

	items = ("#{v.key} - #{v.name}" for v in _choices)

	updateChecked =
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
				return cancel() if key is 'escape'
				updateChecked mapDisplayed[key]

	deferred.promise