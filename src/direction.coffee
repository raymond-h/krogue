exports.directions =
	up: [0, -1]
	top: [0, -1]

	down: [0, 1]
	bottom: [0, 1]

	left: [-1, 0]

	right: [1, 0]

exports.split = (dir) ->
	dir.split /[\s\-]+/

exports.parse = (dir) ->
	exports.split dir
	.map (d) -> exports.get d
	.reduce ((p, c) -> [p[0]+c[0], p[1]+c[1]]), [0, 0]