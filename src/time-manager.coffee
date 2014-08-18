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
		@targets.push targets...

	remove: (targets...) ->
		arrayRemove @targets, t for t in targets

	tick: (callback) ->
		if @targets.length > 0
			target = @targets[0]
			@targets.rotate()

			target.actionPoints ?= 0
			target.actionPoints += _.result target, 'tickRate'

			whilst (-> target.actionPoints > 0),
				->
					winston.silly "begin tick '#{target.name} #{target.constructor.name}'"
					Q target.tick()
					.then (cost) -> target.actionPoints -= cost
					.then ->
						winston.silly "end tick '#{target.name} #{target.constructor.name}'"

			.nodeify callback

		else process.nextTick callback