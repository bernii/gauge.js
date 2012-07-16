# Request Animation Frame Polyfill
# CoffeeScript version of http://paulirish.com/2011/requestanimationframe-for-smart-animating/
do () ->
	vendors = ['ms', 'moz', 'webkit', 'o']
	for vendor in vendors
		if window.requestAnimationFrame
			break
		window.requestAnimationFrame = window[vendor + 'RequestAnimationFrame']
		window.cancelAnimationFrame = window[vendor + 'CancelAnimationFrame'] or window[vendor + 'CancelRequestAnimationFrame']

	browserRequestAnimationFrame = null
	lastId = 0
	isCancelled = {}

	if not requestAnimationFrame
		window.requestAnimationFrame = (callback, element) ->
			currTime = new Date().getTime()
			timeToCall = Math.max(0, 16 - (currTime - lastTime))
			id = window.setTimeout(() ->
				callback(currTime + timeToCall)
			, timeToCall)
			lastTime = currTime + timeToCall
			return id
		# This implementation should only be used with the setTimeout()
		# version of window.requestAnimationFrame().
		window.cancelAnimationFrame = (id) ->
			clearTimeout(id)
	else if not window.cancelAnimationFrame
		browserRequestAnimationFrame = window.requestAnimationFrame
		window.requestAnimationFrame = (callback, element) ->
			myId = ++lastId
			browserRequestAnimationFrame(() ->
				if not isCancelled[myId]
					callback()
			, element)
			return myId
		window.cancelAnimationFrame = (id) ->
			isCancelled[id] = true

String.prototype.hashCode = () ->
	hash = 0
	if this.length == 0
		return hash
	for i in [0...this.length]
		char = this.charCodeAt(i)
		hash = ((hash << 5) - hash) + char
		hash = hash & hash # Convert to 32bit integer
	return hash

secondsToString = (sec) ->
	hr = Math.floor(sec / 3600)
	min = Math.floor((sec - (hr * 3600))/60)
	sec -= ((hr * 3600) + (min * 60))
	sec += '' 
	min += ''
	while min.length < 2
		min = '0' + min
	while sec.length < 2
		sec = '0' + sec
	hr = if hr then hr + ':' else ''
	return hr + min + ':' + sec

formatNumber = (num) ->
		return addCommas(num.toFixed(0))

updateObjectValues = (obj1, obj2) ->
	for own key, val of obj2
		obj1[key] = val

addCommas =(nStr) ->
	nStr += ''
	x = nStr.split('.')
	x1 = x[0]
	x2 = ''
	if x.length > 1
		x2 = '.' + x[1]
	rgx = /(\d+)(\d{3})/
	while rgx.test(x1)
		x1 = x1.replace(rgx, '$1' + ',' + '$2')
	return x1 + x2

class ValueUpdater
	animationSpeed: 32
	constructor: () ->
		AnimationUpdater.add(@)

	update: ->
		if @displayedValue != @value
			if @ctx
				@ctx.clearRect(0, 0, @canvas.width, @canvas.height)
			diff = @value - @displayedValue
			if Math.abs(diff / @animationSpeed) <= 0.001
				@displayedValue = @value
			else
				@displayedValue = @displayedValue + diff / @animationSpeed
			@render()
			return true
		return false

class AnimatedText extends ValueUpdater
	displayedValue: 0
	value: 0

	setVal: (value) ->
		@value = 1 * value

	constructor: (@elem, @text=false) ->
		@value = 1 * @elem.innerHTML
		if @text
			@value = 0
	render: () ->
		if @text
			textVal = secondsToString(@displayedValue.toFixed(0))
		else
			textVal = addCommas(formatNumber(@displayedValue))
		@elem.innerHTML = textVal

AnimatedTextFactory =
	create: (objList) ->
		out = []
		for elem in objList
			out.push(new AnimatedText(elem))
		return out

class GaugePointer
	strokeWidth: 3
	length: 76
	options:
		strokeWidth: 0.035
		length: 0.1
	constructor: (@ctx, @canvas) ->
		# @length = @canvas.height * @options.length
		# @strokeWidth = @canvas.height * @options.strokeWidth
		@setOptions()

	setOptions: (options=null) ->
		updateObjectValues(@options, options)
		@length = @canvas.height * @options.length
		@strokeWidth = @canvas.height * @options.strokeWidth

	render: (angle) ->
		centerX = @canvas.width / 2
		centerY = @canvas.height * 0.9
		
		# angle = Math.PI * 1.45
		x = Math.round(centerX + @length * Math.cos(angle))
		y = Math.round(centerY + @length * Math.sin(angle))

		startX = Math.round(centerX + @strokeWidth * Math.cos(angle - Math.PI/2))
		startY = Math.round(centerY + @strokeWidth * Math.sin(angle - Math.PI/2))

		endX = Math.round(centerX + @strokeWidth * Math.cos(angle + Math.PI/2))
		endY = Math.round(centerY + @strokeWidth * Math.sin(angle + Math.PI/2))

		@ctx.fillStyle = "black"
		@ctx.beginPath()

		@ctx.arc(centerX, centerY, @strokeWidth, 0, Math.PI*2, true)
		@ctx.fill()

		@ctx.beginPath()
		@ctx.moveTo(startX, startY)
		@ctx.lineTo(x, y)
		@ctx.lineTo(endX, endY)
		@ctx.fill()


class Bar
	constructor: (@elem) ->
	updateValues: (arrValues) ->
		@value = arrValues[0]
		@maxValue = arrValues[1]
		@avgValue = arrValues[2]
		@render()

	render: () ->
		if @textField
			@textField.text(formatNumber(@value))

		if @maxValue == 0
			@maxValue = @avgValue * 2

		valPercent = (@value / @maxValue) * 100
		avgPercent = (@avgValue / @maxValue) * 100
		# alert(valPercent)
		$(".bar-value", @elem).css({"width": valPercent + "%"})
		$(".typical-value", @elem).css({"width": avgPercent + "%"})

class Gauge extends ValueUpdater
	elem: null
	value: 20
	maxValue: 80
	# angle: 1.45 * Math.PI
	displayedAngle: 0
	displayedValue: 0
	lineWidth: 40
	paddingBottom: 0.1
	options:
		colorStart: "#6fadcf"
		colorStop: "#8fc0da"
		strokeColor: "#e0e0e0"
		pointer:
			length: 0.8
			strokeWidth: 0.035
		angle: 0.15
		lineWidth: 0.44
		fontSize: 40
	constructor: (@canvas) ->
		super()
		@ctx = @canvas.getContext('2d')
		@gp = new GaugePointer(@ctx, @canvas)
		@setOptions()
		@render()

	setOptions: (options=null) ->
		updateObjectValues(@options, options)
		@lineWidth = @canvas.height * (1 - @paddingBottom) * @options.lineWidth # .2 - .7
		@radius = @canvas.height * (1 - @paddingBottom) - @lineWidth
		@gp.setOptions(@options.pointer)
		if @textField
			@textField.style.fontSize = options.fontSize + 'px'
		return @
	
	set: (value) ->
		@value = value
		if @value > @maxValue
			@maxValue = @value * 1.1
		AnimationUpdater.run()

	getAngle: (value) ->
		return (1 + @options.angle) * Math.PI + (value / @maxValue) * (1 - @options.angle * 2) * Math.PI

	setTextField: (@textField) ->

	render: () ->
		# Draw using canvas
		w = @canvas.width / 2
		h = @canvas.height * (1 - @paddingBottom)
		displayedAngle = @getAngle(@displayedValue)
		if @textField
			@textField.innerHTML = formatNumber(@displayedValue)

		grd = @ctx.createRadialGradient(w, h, 9, w, h, 70)
		@ctx.lineCap = "butt"

		grd.addColorStop(0, @options.colorStart)
		grd.addColorStop(1, @options.colorStop)
		@ctx.strokeStyle = grd
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, (1 + @options.angle) * Math.PI, displayedAngle, false)
		@ctx.lineWidth = @lineWidth
		@ctx.stroke()

		@ctx.strokeStyle = @options.strokeColor
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, displayedAngle, (2 - @options.angle) * Math.PI, false)
		@ctx.stroke()
		@gp.render(displayedAngle)

class Donut extends ValueUpdater
	lineWidth: 15
	displayedValue: 0
	value: 33
	maxValue: 80

	options:
		lineWidth: 0.10
		colorStart: "#6f6ea0"
		colorStop: "#c0c0db"
		strokeColor: "#eeeeee"
		angle: 0.35

	constructor: (@canvas) -> #, @color=["#6fadcf", "#8fc0da"]) ->
		super()
		@ctx = @canvas.getContext('2d')
		# @canvas = @elem[0]
		@setOptions()
		@render()

	getAngle: (value) ->
		return (1 - @options.angle) * Math.PI + (value / @maxValue) * ((2 + @options.angle) - (1 - @options.angle)) * Math.PI

	setOptions: (options=null) ->
		updateObjectValues(@options, options)
		@lineWidth = @canvas.height * @options.lineWidth #0.10
		@radius = @canvas.height / 2 - @lineWidth/2
		if @textField
			@textField.style.fontSize = options.fontSize + 'px'
		return @

	setTextField: (@textField) ->

	set: (value) ->
		@value = value
		if @value > @maxValue
			@maxValue = @value * 1.1
		AnimationUpdater.run()

	render: () ->
		displayedAngle = @getAngle(@displayedValue)
		w = @canvas.width / 2
		h = @canvas.height / 2

		if @textField
			@textField.innerHTML = formatNumber(@displayedValue)

		grdFill = @ctx.createRadialGradient(w, h, 39, w, h, 70)
		grdFill.addColorStop(0, @options.colorStart)
		grdFill.addColorStop(1, @options.colorStop)

		start = @radius - @lineWidth / 2;
		stop = @radius + @lineWidth / 2;

		grd = @ctx.createRadialGradient(w, h, start, w, h, stop)
		grd.addColorStop(0, "#d5d5d5")
		grd.addColorStop(0.12, @options.strokeColor)
		grd.addColorStop(0.88, @options.strokeColor)
		grd.addColorStop(1, "#d5d5d5")

		@ctx.strokeStyle = grd
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, (1 - @options.angle) * Math.PI, (2 + @options.angle) * Math.PI, false)
		@ctx.lineWidth = @lineWidth
		@ctx.lineCap = "round"
		@ctx.stroke()

		@ctx.strokeStyle = grdFill
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, (1 - @options.angle) * Math.PI, displayedAngle, false)
		@ctx.stroke()


window.AnimationUpdater =
	elements: []
	animId: null

	addAll: (list) ->
		for elem in list
			AnimationUpdater.elements.push(elem)

	add: (object) ->
		AnimationUpdater.elements.push(object)

	run: () ->
		animationFinished = true
		for elem in AnimationUpdater.elements
			if elem.update()
				animationFinished = false
		if not animationFinished
			AnimationUpdater.animId = requestAnimationFrame(AnimationUpdater.run)
		else
			cancelAnimationFrame(AnimationUpdater.animId)

window.Gauge = Gauge
window.Donut = Donut

