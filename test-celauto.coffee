Q = require 'q'
_ = require 'lodash'
MersenneTwister = require 'mersennetwister'

MapGenerator = require './src/generation/cellular-automata'
{repeat} = require './src/util'

printMap = (map) ->
	for row in map
		console.error row.join ''

# return '#' if not (0 < x < w-1 and 0 < y < h-1)

# large encompassing caves with tunnels
# initProb = 0.55
# rules = _.flatten [
# 	repeat 4, (..., neighbours) -> neighbours >= 6 or neighbours < 1
# 	repeat 3, (..., neighbours) -> neighbours >= 5
# 	# (..., neighbours) -> neighbours > 3
# 	# (..., neighbours) -> neighbours >= 2
# 	# (..., neighbours) -> neighbours >= 5
# ]

# large encompassing caves with tunnels 2
# initProb = 0.35
# rules = _.flatten [
# 	repeat 2, (..., neighbours) -> neighbours >= 5 or neighbours < 1
# 	repeat 3, (..., neighbours) -> neighbours >= 5
# ]

# huge open cave
# initProb = 0.40
# rules = _.flatten [
# 	repeat 2, (..., neighbours) -> neighbours < 6
# 	repeat 3, (..., neighbours) -> neighbours >= 4
# ]

# also huge cave
# initProb = 0.20
# rules = _.flatten [
# 	repeat 1, (..., neighbours) -> neighbours >= 3
# 	repeat 4, (..., neighbours) -> neighbours >= 5
# ]

initProb = 0.44
rules = _.flatten [
	repeat 6, (..., neighbours) -> neighbours >= 5
	repeat 3, (..., neighbours) -> neighbours >= 4
]

# initProb = 0.40
# rules = _.flatten [
# 	repeat 3, (..., neighbours) -> neighbours >= 5 or neighbours < 1
# 	repeat 2, (..., neighbours) -> neighbours >= 4
# 	repeat 2, (..., neighbours) -> neighbours >= 7
# ]

width = 100
height = 40

console.time 'mapgen'

printMap MapGenerator.createMap {width, height, initProbability: initProb, rules}

console.timeEnd 'mapgen'