class exports.Renderer
	constructor: (@game) ->
		@invalidated = no

	invalidate: ->
		if not @invalidated
			@invalidated = yes

			process.nextNick =>
				@invalidated = no

				@render()

	render: ->