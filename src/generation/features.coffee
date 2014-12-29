game = require '../game'
log = require '../log'

CreatureGen = require './creatures'

randomPoint = (map, pred) ->
	if pred?
		p = randomPoint map

		p = randomPoint map while not pred p

		return p

	if map.top? and map.bottom? and map.left? and map.right?
		x: game.random.range map.left, map.right
		y: game.random.range map.top, map.bottom

	else
		x: game.random.range 0, map.w
		y: game.random.range 0, map.h

randomArea = (map) ->
	p1 = randomPoint map
	p2 = randomPoint map

	min =
		x: Math.min p1.x, p2.x
		y: Math.min p1.y, p2.y

	max =
		x: Math.max p1.x, p2.x
		y: Math.max p1.y, p2.y

	{ top: min.y, left: min.x, right: max.x, bottom: max.y }

exports.generateFeatures = (path, level, map) ->
	log.info 'Generating features...'

	if game.random.chance 1
		exports.generateSpaceBeeHive path, level, map

exports.generateSpaceBeeHive = (path, level, map) ->
	{top, left, right, bottom} = randomArea map

	wall = {
		collidable: yes
		seeThrough: no
		symbol: 'honeycombWall'
	}
	floor = {
		collidable: no
		seeThrough: yes
		symbol: 'honeycombFloor'
	}

	for y in [top...bottom]
		for x in [left...right]
			map.data[y][x] =
				if map.data[y][x].collidable then wall else floor

	group = "space-bee-#{game.random.range 0, 100000}"

	bees = []

	p = randomPoint {top, left, right, bottom}, ({x, y}) -> not map.collidable x, y
	bees.push CreatureGen.generateSpaceBee p.x, p.y, {monarch: yes, group}

	for i in [1..game.random.range 20, 30]
		p = randomPoint {top, left, right, bottom}, ({x, y}) ->
			not map.collidable x, y

		bees.push CreatureGen.generateSpaceBee p.x, p.y, {group}

	map.addEntity bees...

	log.info "Generated space bee hive (#{group}) @", {top, left, right, bottom}