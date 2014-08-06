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
					# console.error "begin tick '#{target.name} #{target.constructor.name}'"
					Q target.tick()
					.then (cost) -> target.actionPoints -= cost
					# .then -> console.error "end tick '#{target.name} #{target.constructor.name}'"

			.nodeify callback

		else process.nextTick callback