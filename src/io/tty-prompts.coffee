_ = require 'lodash'

game = require '../game'
{whilst} = require '../util'

_.extend exports, require './common-prompts'
{pressedKey, listOptions} = exports

exports.list = (header, choices, opts) ->
	_choices = for v, i in choices
		key: v.key ? exports.listOptions[i]
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
		key: v.key ? exports.listOptions[i]
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
			exports.keys null, ['escape', 'enter', (_.keys mapDisplayed)...]

			.then (key) ->
				switch key
					when 'enter' then done = yes
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