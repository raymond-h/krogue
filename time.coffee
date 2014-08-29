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
		# console.log @targets
		target = @targets.pop()

		nextTick = target.tick() / (_.result target, 'tickRate')

		@adjustScheduledTicks -target.scheduledTick
		target.scheduledTick = nextTick
		@add target

time = new TimeManager

totals = {}
add = (name, rate = 12) ->
	time.add
		name: name
		tickRate: rate
		tick: ->
			# console.log name
			totals[name] = (totals[name] ? 0) + 1
			10

add 'a', 9*20
add 'b', 8*20
add 'c', 1*20

for i in [1..251*5] then time.tick()

console.log 'Totals:', totals