class exports.BasePersonality
	weight: (creature) -> 0

	tick: (creature) -> 0

class exports.FleeFromPlayer extends exports.BasePersonality
	constructor: (@safeDist) ->

	weight: (creature) ->
		distanceSq = (e0, e1) ->
			[dx, dy] = [e1.x-e0.x, e1.y-e0.y]
			dx*dx + dy*dy

		if (distanceSq (require './game').player.creature, creature) < (@safeDist*@safeDist)
			100

		else 0

	tick: (creature) ->
		direction = (require './direction')
		ac = (require './game').player.creature

		dir = direction.getDirection ac.x, ac.y, creature.x, creature.y

		creature.move (direction.parse dir)...

		12