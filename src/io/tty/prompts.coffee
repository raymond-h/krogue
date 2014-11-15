_ = require 'lodash'

game = require '../../game'
{whilst, snapToRange} = require '../../util'

_.extend exports, require '../common-prompts'
{pressedKey, listOptions} = exports

direction = require '../../direction'
vectorMath = require '../../vector-math'

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

exports.position = (message, opts = {}) ->
	if message?
		game.message message
		game.renderer.showMoreLogs()

	bounds = null
	if not bounds?
		camera = game.renderer.camera

		bounds = {
			x: 0 + camera.x, y: 1 + camera.y
			w: camera.viewport.w, h: camera.viewport.h
		}

	pos =
		x: opts.default?.x ? camera.x
		y: opts.default?.y ? camera.y

	cancelled = no
	done = no
	whilst (-> not done),
		->
			game.renderer.setCursorPos pos.y - camera.y + 1, pos.x - camera.x + 0

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

						pos.x = snapToRange camera.x, pos.x, (camera.x + camera.viewport.w - 1)
						pos.y = snapToRange camera.y, pos.y, (camera.y + camera.viewport.h - 1)

	.then ->
		if not cancelled then pos
		else null