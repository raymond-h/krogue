winston = require 'winston'
_ = require 'lodash'

{edge, snapToRange} = require './util'

module.exports = class Camera
	constructor: (@viewport, @minBoundDist) ->
		@worldBounds = null
		@x = @y = 0

	bounds: (rect) ->
		@worldBounds =
			_.defaults (_.pick rect, 'x', 'y', 'w', 'h'),
				{ x: 0, y: 0, w: @viewport.w, h: @viewport.h }

	calculateOffset: (relPos, camSize, minBoundDist) ->
		if minBoundDist > relPos then (relPos - minBoundDist)

		else if (camSize - minBoundDist) <= relPos
			(relPos - (camSize - minBoundDist)) + 1

		else 0

	update: ->
		wb = @worldBounds

		if @target?
			@x += @calculateOffset (@target.x - @x), @viewport.w, @minBoundDist.x
			@y += @calculateOffset (@target.y - @y), @viewport.h, @minBoundDist.y

		# keep camera within bounds
		@x = snapToRange (edge wb, 'left'), @x, (edge wb, 'right')-@viewport.w
		@y = snapToRange (edge wb, 'up'), @y, (edge wb, 'down')-@viewport.h

		winston.silly "Updating camera pos to #{@x},#{@y}"