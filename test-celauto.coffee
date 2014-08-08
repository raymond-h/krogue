Q = require 'q'
_ = require 'lodash'

w = 80
h = 30

createMap = (w, h, tileCb) ->
	((tileCb x,y for x in [0...w]) for y in [0...h])

tileAt = (map, x, y) -> map[y]?[x] ? '#'

neighbours = (map, x, y) ->
	tiles =
		for i in [x-1..x+1]
			for j in [y-1..y+1]
				tileAt map, i, j

	(t for t in (_.flatten tiles) when t is '#').length

generation = (map, ruleFunc) ->
	tileCb = (x, y) ->
		if ruleFunc (neighbours map, x, y) then '#' else '.'

	createMap w, h, tileCb

printMap = (map) ->
	for row in map
		console.log row.join ''

randomTiles = (prob) -> (x,y) ->
	return '#' if not (0 < x < w-1 and 0 < y < h-1)

	if Math.random() <= prob then '#' else '.'

map = createMap w, h, randomTiles(0.40)

repeat = (n, item) ->
	item for i in [1..n]

# large encompassing caves with tunnels
# rules = _.flatten [
# 	repeat 4, (neighbours) -> neighbours >= 6 or neighbours < 1
# 	repeat 3, (neighbours) -> neighbours >= 5
# ]

rules = _.flatten [
	repeat 2, (neighbours) -> neighbours % 3 is 0
	repeat 3, (neighbours) -> neighbours >= 4
]

for rule in rules
	printMap map
	console.log '-----'
	map = generation map, rule

printMap map