Promise = require 'bluebird'
_ = require 'lodash'

{whilst, snapToRange} = require '../../util'
eventBus = require '../../event-bus'
direction = require 'rl-directions'
vectorMath = require '../../vector-math'

Prompts = require '../prompts'

module.exports = class WebPrompts extends Prompts
	# On choice taken: {key, value, index}
	# On cancel: null
	list: (header, choices, opts) ->
		new Promise (resolve, reject) =>
			_choices = for v, i in choices
				key: v?.key ? @listOptions[i]
				name: if _.isString v then v else (v.name ? '???')
				orig: v
				index: i

			choicePicked = (index) =>
				@game.renderer.hideMenu()

				choice = _choices[index]
				resolve
					key: choice.key
					value: choices[index]
					index: index

			cancel = =>
				@game.renderer.hideMenu()
				resolve null

			items = ("#{v.key}. #{v.name}" for v in _choices)

			@game.renderer.showSingleChoiceMenu header, items,
				onChoice: choicePicked
				onCancel: cancel

			mapDisplayed = _.zipObject (
				[(@pressedKey v.key), v.index] for v in _choices
			)

			@keys null, ['escape', (_.keys mapDisplayed)...]
			.then (key) ->
				return cancel() if key is 'escape'
				choicePicked mapDisplayed[key]

	# On done taken: [{key, value, index}, ...]
	# On cancel: null
	multichoiceList: (header, choices, opts) ->
		stopped = no

		new Promise (resolve, reject) =>
			_choices = for v, i in choices
				key: v.key ? @listOptions[i]
				name: if _.isString v then v else (v.name ? '???')
				orig: v
				index: i
				checked: no

			done = (indices) =>
				stopped = yes
				@game.renderer.hideMenu()

				finalChoices = indices.map (index) ->
					choice = _choices[index]

					key: choice.key
					value: choices[index]
					index: index

				resolve finalChoices

			cancel = =>
				stopped = yes
				@game.renderer.hideMenu()
				resolve null

			items = ("#{v.key}. #{v.name}" for v in _choices)

			[updateChecked, callbackDone] =
				@game.renderer.showMultiChoiceMenu header, items,
					onDone: done
					onCancel: cancel

			mapDisplayed = _.zipObject (
				[(@pressedKey v.key), v.index] for v in _choices
			)

			whilst (-> not stopped),
				=>
					@keys null, ['escape', 'enter', (_.keys mapDisplayed)...]
					.then (key) ->
						return if stopped
						return cancel() if key is 'escape'
						return callbackDone() if key is 'enter'

						updateChecked mapDisplayed[key]

	position: (message, opts = {}) ->
		@game.renderer.setPromptMessage message

		pos = null

		snapPos = =>
			pos.x = snapToRange 0, pos.x, @game.currentMap.w-1
			pos.y = snapToRange 0, pos.y, @game.currentMap.h-1

		updatePos = (newPos) =>
			pos = newPos
			snapPos()
			opts.progress?(pos)
			@game.renderer.cursor = pos
			@game.renderer.invalidate()

		updatePos
			x: opts.default?.x ? 0
			y: opts.default?.y ? 0

		new Promise (resolve, reject) =>
			# Mouse
			unbindClick =
				@game.renderer.onClick (e) ->
					if pos.x is e.world.x and pos.y is e.world.y
						done no

					else updatePos e.world

			# Keyboard
			handler = (action, dir) ->
				switch @event
					when 'key.escape' then done yes
					when 'key.enter' then done no

					else
						if action is 'direction'
							updatePos (vectorMath.add pos, direction.parse dir)

			(eventBus.on e, handler) for e in ['key.escape', 'key.enter', 'action.**']

			# Done
			done = (cancelled) =>
				unbindClick()
				(eventBus.off e, handler) for e in ['key.escape', 'key.enter', 'action.**']

				@game.renderer.cursor = null
				@game.renderer.invalidate()

				resolve(
					if not cancelled then pos
					else null
				)
