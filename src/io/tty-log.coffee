winston = require 'winston'

exports.log = (params...) ->
	winston.info params...

exports.error = (params...) ->
	winston.error params...