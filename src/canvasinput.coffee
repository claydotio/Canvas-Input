class CanvasInput
	@inputs = [] # static array of all input objects
	constructor: (options) ->		
		x = options.x || 0
		y = options.y || 0
		@placeholder = options.placeholder || ''
		@value = @placeholder
		@width = options.width || 150
		@height = options.height || 30
		@fontSize = options.fontSize || 12
		@padding = options.padding || 5
		@onSubmit = options.onSubmit || ->
		@center = options.center || false # centers text
		@wasOver = false # used for cursor on mouseover (resetting to default)
		
		@ctx = @canvas.getContext '2d'
		@canvasWidth = @canvas.width || parseInt @canvas.style.width
		@canvasHeight = @canvas.height || parseInt @canvas.style.height
		@xPos = if x == 'center' then ( @canvasWidth / 2 - @width / 2 ) else ( x + 1 ) # offset by one since the border goes -1
		@yPos = ( y - @height / 2 ) + 1 # offset by 1 since the border goes -1
		if typeof @defaultBackgroundColor == 'undefined'
			@defaultBackgroundColor = @ctx.createLinearGradient( @xPos, @yPos, @xPos, @yPos + @height ) # top to bottom
			@defaultBackgroundColor.addColorStop( 0, "#d5d5d5" )
			@defaultBackgroundColor.addColorStop( 1, "#eee" )

		@defaultFontColor ||= '#000'
		@defaultStrokeColor ||= '#444'

		
		@inputIndex = CanvasInput.inputs.push( @ ) - 1
	
		@refresh()

		@handleClick = handler = (e) =>
			e ||= window.event
			@click e
		Events.addEvent 'click', handler, false, false, @canvas
		
	destroy: ->
		Events.removeEvent 'click', @handleClick, false, @canvas			
		
	click: (e) ->
		# make sure the click was within the input box coordinates
		x = e.offsetX || e.clientX
		y = e.offsetY || e.clientY
		if @inBox x, y
			@focus()
		else
			@unfocus()			
		
	inBox: (x, y) ->
		return x >= @xPos && x <= @xPos + @width && y >= @yPos && y <= @yPos + @height	

	focus: ->
	
	unfocus: ->
		
	refresh: ->
		@ctx.fillStyle = if @focused then 'black' else @defaultStrokeColor
		@ctx.fillRect @xPos - 1, @yPos - 1, @width + 2, @height + 2 # this is our border, strokerect produces too thick of a border
		
		@ctx.fillStyle = if @focused then '#efefef' else @defaultBackgroundColor
		@ctx.fillRect @xPos, @yPos, @width, @height
		@ctx.fillStyle = @defaultFontColor
		@ctx.font = @fontSize + 'px "Helvetica Neue", "HelveticaNeue", Helvetica, Arial, "Lucida Grande", sans-serif'
		text = if @type == 'password' && @value != @placeholder then @value.replace( /./g, '\u25CF' ) else @value
			
		textWidth = @ctx.measureText( text ).width
			
		offset = @padding
			
		# make sure the text isn't too wide
		if ( ratio = ( textWidth / ( @width - @padding - 3 ) ) ) > 1 # the 3 is just an extra buffer
			text = text.substr -1 * Math.floor( text.length / ratio )
		else if @center
			offset = @width / 2 - textWidth / 2
			
		@ctx.fillText text, @xPos + offset , @yPos + @height / 2 + @fontSize / 2
		
		if @cursorOn
			@ctx.fillStyle = @defaultFontColor
			cursorOffset = @ctx.measureText( text.substring( 0, @cursorPos ) ).width
			if @center
				cursorOffset += offset - @padding
			@ctx.fillRect @xPos + @padding + cursorOffset, @yPos + @padding, 1, @height - 2 * @padding
		
		
class @CanvasText extends CanvasInput
	constructor: (@canvas, options) ->
		@type ||= 'text'
		@cursorPos = 0
		@handleKey = handler = (e) =>
			e ||= window.event
			@keyDown e
		Events.addEvent 'keydown', handler, false, false
		
		@handleMouse = handler = (e) =>
			e ||= window.event
			@mouseMove e
		Events.addEvent 'mousemove', handler, false, false, @canvas
		
		super(options)

	destroy: ->
		Events.removeEvent 'click', @handleClick, false, @canvas	
		Events.removeEvent 'keydown', @handleKey, false

	focus: ->
		return if @focused
		@focused = true
		
		@cursorInterval = setInterval =>
			@cursorOn = !@cursorOn
			@refresh()
		, 500
		
		# bring up keyboard
		isMobile = navigator.userAgent.match(/(iPhone|iPod|iPad|Android|BlackBerry)/)
		if typeof CocoonJS != 'undefined' && CocoonJS.Keyboard && CocoonJS.Keyboard.available
			CocoonJS.Keyboard.Types.TEXT()
		# if there's not an actual keyboard plugged in (mobile devices), AND the DOM isn't available
		else if isMobile && document && document.createElement && input = document.createElement( 'input' )
			input.type = 'text'
			input.style.opacity = 0
			input.style.position = 'absolute'
			input.style.top = @yPos + 'px'
			input.style.left = @xPos + 'px'
			input.style.width = input.style.height = 0
			document.body.appendChild input 
			input.focus()
		else if isMobile
			@value = prompt( @placeholder ) || ''
		
		if @value == @placeholder
			@value = ''
		@refresh()
	unfocus: ->
		@focused = false
		clearInterval @cursorInterval
		@cursorOn = false
		if @value == '' # reset placeholder if still empty
			@value = @placeholder
		@refresh()
			
	mouseMove: (e) ->
		x = e.offsetX || e.clientX
		y = e.offsetY || e.clientY
		if @inBox( x, y ) && @canvas.style
			@canvas.style.cursor = 'text'
			@wasOver = true
		else if @wasOver && @canvas.style
			@canvas.style.cursor = 'default'
			@wasOver = false
		
	keyDown: (e) ->
		if @focused
			e.preventDefault()
			cursorVal = true
			
			if e.which == 8 # backspace
				if @cursorPos > 0
					@value = @value.substr( 0, @cursorPos - 1 ) + @value.substr( @cursorPos, @value.length )
					@cursorPos--
			if e.which == 46 # delete key
				if @cursorPos < @value.length
					@value = @value.substr( 0, @cursorPos ) + @value.substr( @cursorPos + 1, @value.length )
			else if e.which == 37 # left arrow
				@cursorPos--		
			else if e.which == 39 # right arrow
				@cursorPos++				
			else if e.which == 13 # enter key
				# find closest button and execute it
				for input in CanvasInput.inputs
					if input.type == 'submit'
						cursorVal = false # make sure we don't reinstate the cursor
						@unfocus()
						input.focus()
						break
			else if e.which == 9 # tab
				cursorVal = false # make sure we don't reinstate the cursor
				@unfocus()
				if obj = CanvasInput.inputs[@inputIndex + 1]
					setTimeout (-> obj.focus()), 1 # timeout so it doesn't skip completely past it
			else if key = @mapKeyPressToActualCharacter e.shiftKey, e.which 
				@value += key
				@cursorPos++ # move the cursor to the right
			
			@cursorOn = cursorVal
			@refresh()
	# credit to http://stackoverflow.com/a/4786582
	mapKeyPressToActualCharacter: (isShiftKey, characterCode) ->
		return false	if characterCode is 27 or characterCode is 8 or characterCode is 9 or characterCode is 20 or characterCode is 16 or characterCode is 17 or characterCode is 91 or characterCode is 13 or characterCode is 92 or characterCode is 18
		return false	if typeof isShiftKey isnt "boolean" or typeof characterCode isnt "number"
		characterMap = []
		characterMap[192] = "~"
		characterMap[49] = "!"
		characterMap[50] = "@"
		characterMap[51] = "#"
		characterMap[52] = "$"
		characterMap[53] = "%"
		characterMap[54] = "^"
		characterMap[55] = "&"
		characterMap[56] = "*"
		characterMap[57] = "("
		characterMap[48] = ")"
		characterMap[109] = "_"
		characterMap[107] = "+"
		characterMap[219] = "{"
		characterMap[221] = "}"
		characterMap[220] = "|"
		characterMap[59] = ":"
		characterMap[222] = "\""
		characterMap[188] = "<"
		characterMap[190] = ">"
		characterMap[187] = "+"
		characterMap[191] = "?"
		characterMap[32] = " "
		character = ""
		if isShiftKey
			if characterCode >= 65 and characterCode <= 90
				character = String.fromCharCode(characterCode)
			else
				character = characterMap[characterCode]
		else
			if characterCode >= 65 and characterCode <= 90
				character = String.fromCharCode(characterCode).toLowerCase()
			else
				if characterCode == 188 # weird cases (onkeydown produces different key than onkeypress)
					character = ','
				else if characterCode == 190
					character = '.'
				else
					character = String.fromCharCode(characterCode)
		return character

class @CanvasPassword extends @CanvasText
	constructor: (@canvas, options) ->
		@type = 'password'
		super( @canvas, options )
	
class @CanvasSubmit extends CanvasInput
	constructor: (@canvas, options) ->
		@type = 'submit'
		options.center ||= true # centers text
		@defaultBackgroundColor = '#666'
		@defaultFontColor = '#fff'
		@defaultStrokeColor = '#000'
		super( options )
	focus: ->
		@onSubmit()
		
class Events
	@addEvent: ( type, listener, useObject = false, removeListener = false, obj = window ) ->
		# Removes the event when it's called
		if removeListener
			tmp = listener
			listener = (event) =>
				tmp event
				if removeListener
					@removeEvent( type, arguments.callee, useObject, obj )
		
		if obj.addEventListener
			obj.addEventListener type, listener, useObject
		else if obj.attachEvent
			obj.attachEvent 'on'+type, listener, useObject
		else
			obj['on'+type] = listener
	@removeEvent: ( type, listener, useObject = false, obj = window) ->
		if obj.removeEventListener
			obj.removeEventListener type, listener, useObject
		else if obj.detachEvent
			obj.detachEvent 'on'+type, listener, useObject
		else
			obj['on'+type] = null