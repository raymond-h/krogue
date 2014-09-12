logImpl = null

initialize = (logModule) ->
	logImpl = logModule

module.exports = exports = (out...) ->
	logImpl.log out...

exports.e = exports.error = (out...) ->
	logImpl.error out...

exports.initialize = initialize

exports.level = 'info'