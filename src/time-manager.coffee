async = require 'async'
_ = require 'lodash'
Q = require 'q'

{whilst} = require './util'

module.exports = class TimeManager
	constructor: ->
		@targets = []

		@targets.remove = (item) ->
			i = @indexOf item
			@[i..i] = []
			i

		@targets.rotate = ->
			@push @shift()

	tick: (callback) ->
		if @targets.length > 0
			target = @targets[0]
			@targets.rotate()

			target.actionPoints ?= 0
			target.actionPoints += _.result target, 'tickRate'

			whilst (-> target.actionPoints > 0),
				->
					target.tick()
					.then (cost) -> target.actionPoints -= cost

			.nodeify callback

		else process.nextTick callback