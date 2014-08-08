Q = require 'q'
_ = require 'lodash'

{createMapData, randomTiles, cellularAutomataGeneration} = require './src/map-generation'
{repeat} = require './src/util'

printMap = (map) ->
	for row in map
		console.log row.join ''

# return '#' if not (0 < x < w-1 and 0 < y < h-1)

# large encompassing caves with tunnels
initProb = 0.40
rules = _.flatten [
	repeat 2, (neighbours) -> neighbours >= 6 or neighbours < 2
	repeat 3, (neighbours) -> neighbours >= 5
]

# large encompassing caves with tunnels 2
# initProb = 0.35
# rules = _.flatten [
# 	repeat 2, (neighbours) -> neighbours >= 5 or neighbours < 1
# 	repeat 3, (neighbours) -> neighbours >= 5
# ]

# huge open cave
# initProb = 0.40
# rules = _.flatten [
# 	repeat 2, (neighbours) -> neighbours % 4 is 0
# 	repeat 3, (neighbours) -> neighbours >= 4
# ]

# also huge cave
# initProb = 0.20
# rules = _.flatten [
# 	repeat 1, (neighbours) -> neighbours >= 3
# 	repeat 4, (neighbours) -> neighbours >= 5
# ]

# initProb = 0.45
# rules = _.flatten [
# 	repeat 6, (neighbours) -> neighbours >= 5
# 	repeat 4, (neighbours) -> neighbours >= 4
# ]

# initProb = 0.20
# rules = _.flatten [
# 	repeat 1, (neighbours) -> neighbours >= 3
# 	repeat 4, (neighbours) -> neighbours >= 5
# ]

w = 80
h = 30

map = createMapData w, h, randomTiles(Math.random, initProb)

for rule in rules
	# printMap map
	# console.log '-----'
	map = cellularAutomataGeneration map, w, h, rule

printMap map