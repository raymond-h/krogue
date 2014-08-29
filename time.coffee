_ = require 'lodash'

class TimeManager
	constructor: ->
		@targets = []

	add: (target) ->
		target.scheduledTick ?= 0
		
		i = _.sortedIndex @targets, target, (t) -> -t.scheduledTick
		@targets.splice i, 0, target

	adjustScheduledTicks: (add) ->
		(t.scheduledTick += add) for t in @targets

	tick: ->
		target = @targets.pop()

		nextTick = target.tick() / (_.result target, 'tickRate')
		@adjustScheduledTicks -nextTick

		target.scheduledTick += nextTick
		@add target

time = new TimeManager

totals = {}
add = (name, rate = 12) ->
	time.add
		name: name
		tickRate: rate
		tick: ->
			console.log name
			totals[name] = (totals[name] ? 0) + 1
			10

add 'a', 1
add 'b', 2
add 'c', 1

for i in [1..32] then time.tick()

console.log 'Totals:', totals