printMap = (map) ->
	for row in map
		console.error row.join ''

neighbourCount = (data, x, y) ->
	count = 0

	for i in [x-1..x+1]
		for j in [y-1..y+1]
			if (data[j]?[i] ? 1) is 1 then count++

	count

initialMap = (width, height, wallProb, randomFn = Math.random) ->
	for y in [0...height]
		for x in [0...width]
			if x in [0, width-1] or y in [0, height-1]
				1

			else if (randomFn() <= wallProb) then 1 else 0

generation = (width, height, data, ruleFn) ->
	for y in [0...height]
		for x in [0...width]
			isWall = ruleFn x, y, (neighbourCount data, x, y)

			if isWall then 1 else 0

exports.createMap = ({width, height, initProbability, rules, randomFn}) ->
	data = initialMap width, height, initProbability, randomFn

	for ruleFn in rules
		data = generation width, height, data, ruleFn

	data