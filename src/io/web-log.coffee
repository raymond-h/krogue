log = (params...) ->
	console.log params...

error = (params...) ->
	console.error params...

exports.log = (level, params...) ->
	llog = if level is 'error' then error else log

	llog "#{level}:", params...