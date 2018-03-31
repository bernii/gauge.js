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

secondsToString = (sec) ->
	hr = Math.floor(sec / 3600)
	min = Math.floor((sec - (hr * 3600)) / 60)
	sec -= ((hr * 3600) + (min * 60))
	sec += ''
	min += ''
	while min.length < 2
		min = '0' + min
	while sec.length < 2
		sec = '0' + sec
	hr = if hr then hr + ':' else ''
	return hr + min + ':' + sec

formatNumber = (num...) ->
	value = num[0]
	digits = 0 || num[1]
	return addCommas(value.toFixed(digits))

mergeObjects = (obj1, obj2) ->
	out = {}
	for own key, val of obj1
		out[key] = val
	for own key, val of obj2
		out[key] = val
	return out

addCommas = (nStr) ->
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

cutHex = (nStr) ->
	if nStr.charAt(0) == "#"
		return nStr.substring(1, 7)
	return nStr

class ValueUpdater
	animationSpeed: 32
	constructor: (addToAnimationQueue = true, @clear = true) ->
		if addToAnimationQueue
			AnimationUpdater.add(@)

	update: (force = false) ->
		if force or @displayedValue != @value
			if @ctx and @clear
				@ctx.clearRect(0, 0, @canvas.width, @canvas.height)
			diff = @value - @displayedValue
			if Math.abs(diff / @animationSpeed) <= 0.001
				@displayedValue = @value
			else
				@displayedValue = @displayedValue + diff / @animationSpeed
			@render()
			return true
		return false

class BaseGauge extends ValueUpdater
	displayScale: 1
	forceUpdate: true

	setTextField: (textField, fractionDigits) ->
		@textField = if textField instanceof TextRenderer then textField else new TextRenderer(textField, fractionDigits)

	setMinValue: (@minValue, updateStartValue = true) ->
		if updateStartValue
			@displayedValue = @minValue
			for gauge in @gp or []
				gauge.displayedValue = @minValue

	setOptions: (options = null) ->
		@options = mergeObjects(@options, options)
		if @textField
			@textField.el.style.fontSize = options.fontSize + 'px'

		if @options.angle > .5
			@options.angle = .5
		@configDisplayScale()
		return @

	configDisplayScale: () ->
		prevDisplayScale = @displayScale

		if @options.highDpiSupport == false
			delete @displayScale
		else
			devicePixelRatio = window.devicePixelRatio or 1
			backingStorePixelRatio =
				@ctx.webkitBackingStorePixelRatio or
				@ctx.mozBackingStorePixelRatio or
				@ctx.msBackingStorePixelRatio or
				@ctx.oBackingStorePixelRatio or
				@ctx.backingStorePixelRatio or 1
			@displayScale = devicePixelRatio / backingStorePixelRatio

		if @displayScale != prevDisplayScale
			width = @canvas.G__width or @canvas.width
			height = @canvas.G__height or @canvas.height
			@canvas.width = width * @displayScale
			@canvas.height = height * @displayScale
			@canvas.style.width = "#{width}px"
			@canvas.style.height = "#{height}px"
			@canvas.G__width = width
			@canvas.G__height = height

		return @

	parseValue: (value) ->
		value =  parseFloat(value) || Number(value)
		return if isFinite(value) then value else 0

class TextRenderer
	constructor: (@el, @fractionDigits) ->

	# Default behaviour, override to customize rendering
	render: (gauge) ->
		@el.innerHTML = formatNumber(gauge.displayedValue, @fractionDigits)

class AnimatedText extends ValueUpdater
	displayedValue: 0
	value: 0

	setVal: (value) ->
		@value = 1 * value

	constructor: (@elem, @text = false) ->
		super()
		if @elem is undefined
			throw new Error 'The element isn\'t defined.'
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

class GaugePointer extends ValueUpdater
	displayedValue: 0
	value: 0
	options:
		strokeWidth: 0.035
		length: 0.1
		color: "#000000"
		iconPath: null
		iconScale: 1.0
		iconAngle: 0
	img: null

	constructor: (@gauge) ->
		#super()
		if @gauge is undefined
			throw new Error 'The element isn\'t defined.'
		@ctx = @gauge.ctx
		@canvas = @gauge.canvas
		super(false, false)
		@setOptions()

	setOptions: (options = null) ->
		@options = mergeObjects(@options, options)
		@length = 2 * @gauge.radius * @gauge.options.radiusScale * @options.length
		@strokeWidth = @canvas.height * @options.strokeWidth
		@maxValue = @gauge.maxValue
		@minValue = @gauge.minValue
		@animationSpeed =  @gauge.animationSpeed
		@options.angle = @gauge.options.angle
		if @options.iconPath
			@img = new Image()
			@img.src = @options.iconPath

	render: () ->
		angle = @gauge.getAngle.call(@, @displayedValue)

		x = Math.round(@length * Math.cos(angle))
		y = Math.round(@length * Math.sin(angle))

		startX = Math.round(@strokeWidth * Math.cos(angle - Math.PI / 2))
		startY = Math.round(@strokeWidth * Math.sin(angle - Math.PI / 2))

		endX = Math.round(@strokeWidth * Math.cos(angle + Math.PI / 2))
		endY = Math.round(@strokeWidth * Math.sin(angle + Math.PI / 2))

		@ctx.beginPath()
		@ctx.fillStyle = @options.color
		@ctx.arc(0, 0, @strokeWidth, 0, Math.PI * 2, false)
		@ctx.fill()

		@ctx.beginPath()
		@ctx.moveTo(startX, startY)
		@ctx.lineTo(x, y)
		@ctx.lineTo(endX, endY)
		@ctx.fill()

		if @img
			imgX = Math.round(@img.width * @options.iconScale)
			imgY = Math.round(@img.height * @options.iconScale)
			@ctx.save()
			@ctx.translate(x, y)
			@ctx.rotate(angle + Math.PI / 180.0 * (90 + @options.iconAngle))
			@ctx.drawImage(@img, -imgX / 2, -imgY / 2, imgX, imgY)
			@ctx.restore()


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

		$(".bar-value", @elem).css( { "width": valPercent + "%" } )
		$(".typical-value", @elem).css( { "width": avgPercent + "%" } )

class Gauge extends BaseGauge
	elem: null
	value: [20] # we support multiple pointers
	maxValue: 80
	minValue: 0
	displayedAngle: 0
	displayedValue: 0
	lineWidth: 40
	paddingTop: 0.1
	paddingBottom: 0.1
	percentColors: null,
	options:
		colorStart: "#6fadcf"
		colorStop: undefined
		gradientType: 0       	# 0 : radial, 1 : linear
		strokeColor: "#e0e0e0"
		pointer:
			length: 0.8
			strokeWidth: 0.035
			iconScale: 1.0
		angle: 0.15
		lineWidth: 0.44
		radiusScale: 1.0
		fontSize: 40
		limitMax: false
		limitMin: false

	constructor: (@canvas) ->
		super()
		@percentColors = null
		if typeof G_vmlCanvasManager != 'undefined'
			@canvas = window.G_vmlCanvasManager.initElement(@canvas)
		@ctx = @canvas.getContext('2d')
		# Set canvas size to parent size
		h = @canvas.clientHeight
		w = @canvas.clientWidth
		@canvas.height = h
		@canvas.width = w

		@gp = [new GaugePointer(@)]
		@setOptions()
		

	setOptions: (options = null) ->
		super(options)
		@configPercentColors()
		@extraPadding = 0
		if @options.angle < 0
			phi = Math.PI * (1 + @options.angle)
			@extraPadding = Math.sin(phi)
		@availableHeight = @canvas.height * (1 - @paddingTop - @paddingBottom)
		@lineWidth = @availableHeight * @options.lineWidth # .2 - .7
		@radius = (@availableHeight - @lineWidth / 2) / (1.0 + @extraPadding)
		@ctx.clearRect(0, 0, @canvas.width, @canvas.height)
		
		for gauge in @gp
			gauge.setOptions(@options.pointer)
			gauge.render()
		@render()
		return @

	configPercentColors: () ->
		@percentColors = null
		if (@options.percentColors != undefined)
			@percentColors = new Array()
			for i in [0..(@options.percentColors.length - 1)]
				rval = parseInt((cutHex(@options.percentColors[i][1])).substring(0, 2), 16)
				gval = parseInt((cutHex(@options.percentColors[i][1])).substring(2, 4), 16)
				bval = parseInt((cutHex(@options.percentColors[i][1])).substring(4, 6), 16)
				@percentColors[i] = { pct: @options.percentColors[i][0], color: { r: rval, g: gval, b: bval } }

	set: (value) ->
		if not (value instanceof Array)
			value = [value]
		# Ensure values are OK
		for i in [0..(value.length - 1)]
			value[i] = @parseValue(value[i])

		# check if we have enough GaugePointers initialized
		# lazy initialization
		if value.length > @gp.length
			for i in [0...(value.length - @gp.length)]
				gp = new GaugePointer(@)
				gp.setOptions(@options.pointer)
				@gp.push(gp)
		else if value.length < @gp.length
			# Delete redundant GaugePointers
			@gp = @gp.slice(@gp.length - value.length)

		# get max value and update pointer(s)
		i = 0

		for val in value
			# Limit pointer within min and max?
			if val > @maxValue
				if @options.limitMax
					val = @maxValue
				else
					@maxValue = val + 1

			else if val < @minValue
				if @options.limitMin
					val = @minValue
				else
					@minValue = val - 1

			@gp[i].value = val
			@gp[i++].setOptions( { minValue: @minValue, maxValue: @maxValue, angle: @options.angle } )
		@value = Math.max(Math.min(value[value.length - 1], @maxValue), @minValue) # TODO: Span maybe??

		# Force first .set()
		AnimationUpdater.run(@forceUpdate)
		@forceUpdate = false

	getAngle: (value) ->
		return (1 + @options.angle) * Math.PI + ((value - @minValue) / (@maxValue - @minValue)) * (1 - @options.angle * 2) * Math.PI

	getColorForPercentage: (pct, grad) ->
		if pct == 0
			color = @percentColors[0].color
		else
			color = @percentColors[@percentColors.length - 1].color
			for i in [0..(@percentColors.length - 1)]
				if (pct <= @percentColors[i].pct)
					if grad == true
						# Gradually change between colors
						startColor = @percentColors[i - 1] || @percentColors[0]
						endColor = @percentColors[i]
						rangePct = (pct - startColor.pct) / (endColor.pct - startColor.pct)  # How far between both colors
						color = {
							r: Math.floor(startColor.color.r * (1 - rangePct) + endColor.color.r * rangePct),
							g: Math.floor(startColor.color.g * (1 - rangePct) + endColor.color.g * rangePct),
							b: Math.floor(startColor.color.b * (1 - rangePct) + endColor.color.b * rangePct)
						}
					else
						color = @percentColors[i].color
					break
		return 'rgb(' + [color.r, color.g, color.b].join(',') + ')'

	getColorForValue: (val, grad) ->
		pct = (val - @minValue) / (@maxValue - @minValue)
		return @getColorForPercentage(pct, grad)

	renderStaticLabels: (staticLabels, w, h, radius) ->
		@ctx.save()
		@ctx.translate(w, h)

		# Scale font size the hard way - assuming size comes first.
		font = staticLabels.font or "10px Times"
		re = /\d+\.?\d?/
		match = font.match(re)[0]
		rest = font.slice(match.length)
		fontsize = parseFloat(match) * this.displayScale
		@ctx.font = fontsize + rest
		@ctx.fillStyle = staticLabels.color || "#000000"

		@ctx.textBaseline = "bottom"
		@ctx.textAlign = "center"
		for value in staticLabels.labels
			if (value.label != undefined)
				# Draw labels depending on limitMin/Max
				if (not @options.limitMin or value >= @minValue) and (not @options.limitMax or value <= @maxValue)
					font = value.font || staticLabels.font
					match = font.match(re)[0]
					rest = font.slice(match.length)
					fontsize = parseFloat(match) * this.displayScale
					@ctx.font = fontsize + rest
									
					rotationAngle = @getAngle(value.label) - 3 * Math.PI / 2
					@ctx.rotate(rotationAngle)
					@ctx.fillText(formatNumber(value.label, staticLabels.fractionDigits), 0, -radius - @lineWidth / 2)
					@ctx.rotate(-rotationAngle)

			else
				# Draw labels depending on limitMin/Max
				if (not @options.limitMin or value >= @minValue) and (not @options.limitMax or value <= @maxValue)
					rotationAngle = @getAngle(value) - 3 * Math.PI / 2
					@ctx.rotate(rotationAngle)
					@ctx.fillText(formatNumber(value, staticLabels.fractionDigits), 0, -radius - @lineWidth / 2)
					@ctx.rotate(-rotationAngle)
			
		@ctx.restore()

	renderTicks: (ticksOptions, w, h, radius) ->
		if ticksOptions != {}
			divisionCount = ticksOptions.divisions || 0
			subdivisionCount = ticksOptions.subDivisions || 0
			divColor = ticksOptions.divColor || '#fff'
			subColor = ticksOptions.subColor || '#fff'
			divLength = ticksOptions.divLength || 0.7 # default
			subLength = ticksOptions.subLength || 0.2 # default
			range = parseFloat(@maxValue) - parseFloat(@minValue) # total value range
			rangeDivisions = parseFloat(range) / parseFloat(ticksOptions.divisions) # get division step
			subDivisions = parseFloat(rangeDivisions) / parseFloat(ticksOptions.subDivisions)
			currentDivision = parseFloat(@minValue)
			currentSubDivision = 0.0 + subDivisions
			lineWidth = range / 400 # base
			divWidth = lineWidth * (ticksOptions.divWidth || 1)
			subWidth = lineWidth * (ticksOptions.subWidth || 1)

			for t in [0...divisionCount + 1] by 1
				@ctx.lineWidth = @lineWidth * divLength
				scaleMutate = (@lineWidth / 2) * ( 1 - divLength)
				tmpRadius = (@radius * @options.radiusScale) + scaleMutate
				
				@ctx.strokeStyle = divColor
				@ctx.beginPath()
				@ctx.arc(0, 0, tmpRadius, @getAngle(currentDivision - divWidth), @getAngle(currentDivision + divWidth), false)
				@ctx.stroke()

				currentSubDivision = currentDivision + subDivisions
				currentDivision += rangeDivisions
				if t != ticksOptions.divisions && subdivisionCount > 0 # if its not the last marker then draw subs
					for st in [0...subdivisionCount - 1] by 1
						@ctx.lineWidth = @lineWidth * subLength
						scaleMutate = (@lineWidth / 2) * ( 1 - subLength)
						tmpRadius = (@radius * @options.radiusScale) + scaleMutate
						
						@ctx.strokeStyle = subColor
						@ctx.beginPath()
						@ctx.arc(0, 0, tmpRadius, @getAngle(currentSubDivision - subWidth), @getAngle(currentSubDivision + subWidth), false)
						@ctx.stroke()
						currentSubDivision += subDivisions

			#@ctx.restore()

	render: () ->
		# Draw using canvas
		w = @canvas.width / 2
		h = (@canvas.height * @paddingTop + @availableHeight) - ((@radius + @lineWidth / 2) * @extraPadding)
		displayedAngle = @getAngle(@displayedValue)
		if @textField
			@textField.render(@)

		@ctx.lineCap = "butt"
		radius = @radius * @options.radiusScale
		if (@options.staticLabels)
			@renderStaticLabels(@options.staticLabels, w, h, radius)
		
		if (@options.staticZones)
			@ctx.save()
			@ctx.translate(w, h)
			@ctx.lineWidth = @lineWidth
			for zone in @options.staticZones
				# Draw zones depending on limitMin/Max
				min = zone.min
				if @options.limitMin and min < @minValue
					min = @minValue
				max = zone.max
				if @options.limitMax and max > @maxValue
					max = @maxValue
				tmpRadius = (@radius * @options.radiusScale)
				if (zone.height)
					@ctx.lineWidth = @lineWidth * zone.height
					scaleMutate = (@lineWidth / 2) * (zone.offset || 1 - zone.height)
					tmpRadius = (@radius * @options.radiusScale) + scaleMutate
				
				@ctx.strokeStyle = zone.strokeStyle
				@ctx.beginPath()
				@ctx.arc(0, 0, tmpRadius, @getAngle(min), @getAngle(max), false)
				@ctx.stroke()

		else
			if @options.customFillStyle != undefined
				fillStyle = @options.customFillStyle(@)
			else if @percentColors != null
				fillStyle = @getColorForValue(@displayedValue, @options.generateGradient)
			else if @options.colorStop != undefined
				if @options.gradientType == 0
					fillStyle = this.ctx.createRadialGradient(w, h, 9, w, h, 70)
				else
					fillStyle = this.ctx.createLinearGradient(0, 0, w, 0)
				fillStyle.addColorStop(0, @options.colorStart)
				fillStyle.addColorStop(1, @options.colorStop)
			else
				fillStyle = @options.colorStart
			@ctx.strokeStyle = fillStyle

			@ctx.beginPath()
			@ctx.arc(w, h, radius, (1 + @options.angle) * Math.PI, displayedAngle, false)
			@ctx.lineWidth = @lineWidth
			@ctx.stroke()

			@ctx.strokeStyle = @options.strokeColor
			@ctx.beginPath()
			@ctx.arc(w, h, radius, displayedAngle, (2 - @options.angle) * Math.PI, false)
			@ctx.stroke()
			@ctx.save()
			@ctx.translate(w, h)
		
		if (@options.renderTicks)
			@renderTicks(@options.renderTicks, w, h, radius)

		
		@ctx.restore()
		# Draw pointers from (w, h)

		@ctx.translate(w, h)
		for gauge in @gp
			gauge.update(true)
		@ctx.translate(-w, -h)


class BaseDonut extends BaseGauge
	lineWidth: 15
	displayedValue: 0
	value: 33
	maxValue: 80
	minValue: 0

	options:
		lineWidth: 0.10
		colorStart: "#6f6ea0"
		colorStop: "#c0c0db"
		strokeColor: "#eeeeee"
		shadowColor: "#d5d5d5"
		angle: 0.35
		radiusScale: 1.0

	constructor: (@canvas) ->
		super()
		if typeof G_vmlCanvasManager != 'undefined'
			@canvas = window.G_vmlCanvasManager.initElement(@canvas)
		@ctx = @canvas.getContext('2d')
		@setOptions()
		@render()

	getAngle: (value) ->
		return (1 - @options.angle) * Math.PI + ((value - @minValue) / (@maxValue - @minValue)) * ((2 + @options.angle) - (1 - @options.angle)) * Math.PI

	setOptions: (options = null) ->
		super(options)
		@lineWidth = @canvas.height * @options.lineWidth
		@radius = @options.radiusScale * (@canvas.height / 2 - @lineWidth / 2)
		return @

	set: (value) ->
		@value = @parseValue(value)
		if @value > @maxValue
			if @options.limitMax
				@value = @maxValue
			else
				@maxValue = @value
		else if @value < @minValue
			if @options.limitMin
				@value = @minValue
			else
				@minValue = @value

		AnimationUpdater.run(@forceUpdate)
		@forceUpdate = false

	render: () ->
		displayedAngle = @getAngle(@displayedValue)
		w = @canvas.width / 2
		h = @canvas.height / 2

		if @textField
			@textField.render(@)

		grdFill = @ctx.createRadialGradient(w, h, 39, w, h, 70)
		grdFill.addColorStop(0, @options.colorStart)
		grdFill.addColorStop(1, @options.colorStop)

		start = @radius - @lineWidth / 2
		stop = @radius + @lineWidth / 2

		@ctx.strokeStyle = @options.strokeColor
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, (1 - @options.angle) * Math.PI, (2 + @options.angle) * Math.PI, false)
		@ctx.lineWidth = @lineWidth
		@ctx.lineCap = "round"
		@ctx.stroke()

		@ctx.strokeStyle = grdFill
		@ctx.beginPath()
		@ctx.arc(w, h, @radius, (1 - @options.angle) * Math.PI, displayedAngle, false)
		@ctx.stroke()


class Donut extends BaseDonut
	strokeGradient: (w, h, start, stop) ->
		grd = @ctx.createRadialGradient(w, h, start, w, h, stop)
		grd.addColorStop(0, @options.shadowColor)
		grd.addColorStop(0.12, @options._orgStrokeColor)
		grd.addColorStop(0.88, @options._orgStrokeColor)
		grd.addColorStop(1, @options.shadowColor)
		return grd

	setOptions: (options = null) ->
		super(options)
		w = @canvas.width / 2
		h = @canvas.height / 2
		start = @radius - @lineWidth / 2
		stop = @radius + @lineWidth / 2
		@options._orgStrokeColor = @options.strokeColor
		@options.strokeColor = @strokeGradient(w, h, start, stop)
		return @

window.AnimationUpdater =
	elements: []
	animId: null

	addAll: (list) ->
		for elem in list
			AnimationUpdater.elements.push(elem)

	add: (object) ->
		AnimationUpdater.elements.push(object)

	run: (force = false) ->
		# 'force' can take three values, for which these paths should be taken
		#   true: Force repaint of the gauges (typically on first Gauge.set)
		#   false: Schedule repaint (2nd or later call to Gauge.set)
		#   a number: It's a callback. Repaint and schedule new callback if not done.
		isCallback = isFinite(parseFloat(force))
		if isCallback or force is true
			finished = true
			for elem in AnimationUpdater.elements
				if elem.update(force is true)
					finished = false
			AnimationUpdater.animId = if finished then null else requestAnimationFrame(AnimationUpdater.run)
		else if force is false
			if AnimationUpdater.animId is not null
				# Cancel pending callback if animId is already set to avoid overflow
				cancelAnimationFrame(AnimationUpdater.animId)
			AnimationUpdater.animId = requestAnimationFrame(AnimationUpdater.run)

if typeof window.define == 'function' && window.define.amd?
	define(() ->
		{
			Gauge: Gauge,
			Donut: Donut,
			BaseDonut: BaseDonut,
			TextRenderer: TextRenderer
		}
	)
else if typeof module != 'undefined' && module.exports?
	module.exports = {
		Gauge: Gauge,
		Donut: Donut,
		BaseDonut: BaseDonut,
		TextRenderer: TextRenderer
	}
else
	window.Gauge = Gauge
	window.Donut = Donut
	window.BaseDonut = BaseDonut
	window.TextRenderer = TextRenderer
