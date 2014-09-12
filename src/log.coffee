logImpl = null
logLevel = null

# As taken from npm source code (a subset)
levels =
	silly: -Infinity
	verbose: 0
	info: 1
	error: Infinity

initialize = (level, logModule) ->
	logLevel = level
	logImpl = logModule

module.exports = exports = (out...) ->
	exports.level 'info', out...

for name of levels
	exports[name[0]] = exports[name] =
		(out...) ->
			exports.level name, out...

exports.level = (level, out...) ->
	if levels[level ? 'error'] <= levels[logLevel]
		logImpl.log level, out...

exports.initialize = initialize
exports.levels = levels