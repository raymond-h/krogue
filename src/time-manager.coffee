winston = require 'winston'
async = require 'async'
_ = require 'lodash'
Q = require 'q'

{whilst, arrayRemove} = require './util'

module.exports = class TimeManager
	constructor: ->
		@targets = []

		@targets.rotate = ->
			@push @shift()

	add: (targets...) ->
		for target in targets
			target.nextTick ?= 0

			i = _.sortedIndex @targets, target, (t) -> -t.nextTick
			@targets.splice i, 0, target

	remove: (targets...) ->
		arrayRemove @targets, t for t in targets

	adjustNextTicks: (add) ->
		(t.nextTick += add) for t in @targets

	tick: (callback) ->
		if @targets.length > 0
			target = @targets.pop()

			winston.silly "begin tick '#{target.name} #{target.constructor.name}'"

			Q.fcall -> target.tick()
			.then (cost = 0) =>
				nextTick = cost / (_.result target, 'tickRate')

				# finite nextTick means this target should be scheduled again
				if _.isFinite nextTick
					@adjustNextTicks -target.nextTick
					target.nextTick = nextTick

				# otherwise, if infinite, it should never be scheduled
				# logically, this means an infinite amount of time until next schedule
				else target.nextTick = Infinity

				@add target

			.then -> winston.silly "end tick '#{target.name} #{target.constructor.name}'"

			.nodeify callback

		else process.nextTick callback