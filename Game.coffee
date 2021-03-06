define ["utils", "Tangle", "Source", "Drawing", "SoundEffects", "ColourManager", "CanvasViewPort"], (utils, Tangle, Source, Drawing, SoundEffects, ColourManager, CanvasViewPort) ->
  class Game
    constructor: (@canvas) ->
      @properties =
        soundOn: false
        maxConnectionsPerNode: 4
        maxNeighbours: 7
        tickLength: 150
      @paused = true
      @mouseDragging = false
      @startTime = null
      @time = 0
      @nextTick = 0
      @width = @canvas.width
      @height = @canvas.height
      @border = 15
      @fps = 0
      @fps_now
      @fps_last = new Date()
      @fogOfWar = true
      @tangleCanvas = document.createElement("canvas")
      @tangleCanvas.width = @canvas.width
      @tangleCanvas.height = @canvas.height
      @fogOfWarCanvas = document.createElement("canvas")
      @fogOfWarCanvas.width = @canvas.width
      @fogOfWarCanvas.height = @canvas.height

      @viewport = new CanvasViewPort(@canvas)

      @soundEffects = new SoundEffects(this)

      @colourManager = new ColourManager()

      @setupEventHandlers()

      @tangle = new Tangle(this)

      @sources = (for i in [1..10]
        new Source(
          null,
          4 * @border + (@width - 8 * @border) * Math.random(),
          4 * @border + (@height - 8 * @border) * Math.random(),
          5
        )
      )

      @tangle.addSource(@sources.pop())

      @drawing = new Drawing(this)

    start: ->
      console.log "Starting Game"
      @paused = false
      @mainLoop()

    pause: =>
      console.log "Pausing Game"
      @paused = true

    mainLoop: (time) =>
      @fps_now = new Date()
      @fps = 1000 / (@fps_now - @fps_last)
      @fps_last = @fps_now
      document.getElementById('fps').innerHTML = @tangle.allNodes().length + " nodes; " + Math.round(@fps) + " fps"
      if not @paused then window.requestAnimationFrame(@mainLoop)
      if !@startTime
        @startTime = time
        console.log @startTime
      @time = time - @startTime

      if @time >= @nextTick
        @update()
        @nextTick = @time + @properties.tickLength
      @draw()
      @colourManager.updateOutput()

    draw: ->
      @drawing.render(@sources, @tangle)

    update: ->
      @tangle.growRandomly(1, 0.1)
      @tangle.growRandomly(2, 0.0001)

      hit = @viewport.canvasToScene(@lastKnownMouse) if @lastKnownMouse
      if hit and @mouseDragging and @tangle.allNodes().length > 0
        if not @tangle.activeNode
          closest = utils.findClosestInSet(hit, @tangle.findNodesNear(hit))
          if closest
            distToClosest = utils.distanceBetween(hit, closest) - closest.size()
            if distToClosest < @tangle.maxGrowDistance
              @tangle.activeNode = closest
        else
          distToActive = utils.distanceBetween(hit, @tangle.activeNode) - @tangle.activeNode.size()
          if @mouseDragging and distToActive >= @tangle.minGrowDistance
            distance = @tangle.activeNode.size() + @tangle.minGrowDistance + Math.random() * (@tangle.maxGrowDistance - @tangle.minGrowDistance)
            p = utils.offsetFrom(@tangle.activeNode, distance, Math.atan2(hit.y - @tangle.activeNode.y, hit.x - @tangle.activeNode.x))
            newNode = @tangle.grow(p, @tangle.activeNode)
            @tangle.activeNode = newNode
            @playSound("grow_active", newNode)

      @tangle.preUpdate()
      @tangle.update()

    setupEventHandlers: ->
      starting = (event) =>
        event.preventDefault()
        @mouseDragging = true
      stopping = (event) =>
        event.preventDefault()
        @mouseDragging = false
        @tangle.activeNode = null
      moving = (event) =>
        @prevMouse = @lastKnownMouse
        if event.changedTouches?.length > 0 # touch event handling
          @lastKnownMouse = utils.getMouse(event.changedTouches[0], @canvas) # use the first touch event TODO multi touch events
        else
          @lastKnownMouse = utils.getMouse(event, @canvas)

        if @mouseDragging and not @tangle.activeNode and @prevMouse # pan the view
            oldMouse = @viewport.canvasToScene(@prevMouse)
            newMouse = @viewport.canvasToScene(@lastKnownMouse)
            @viewport.view.translate({x:oldMouse.x - newMouse.x, y: oldMouse.y - newMouse.y})
      zoom = (event) =>
        scale = if (event.deltaY < 0) then 0.95 else 1 / 0.95
        @viewport.view.scaleAroundPoint(@viewport.canvasToScene(utils.getMouse(event, @canvas)), scale)
        event.preventDefault()
        event.stopPropagation()

      @canvas.addEventListener "mousemove", moving
      # Super simple dragging detection. TODO will need to revisit when behaviour advances
      @canvas.addEventListener "mousedown", starting
      @canvas.addEventListener "mouseup", stopping
      @canvas.addEventListener "touchstart", starting
      @canvas.addEventListener "touchend", stopping
      @canvas.addEventListener "touchcancel", stopping
      @canvas.addEventListener "touchleave", stopping
      @canvas.addEventListener "touchmove", moving
      @canvas.addEventListener "wheel", zoom

    inBounds: (p) ->
      p.x > @border and p.x < @width - @border and p.y > @border and p.y < @height - @border

    playSound: (event, param) ->
      switch event
        when "grow_active", "grow_random"
          @soundEffects.playSoundAt("grow", param)
        when "die"
          @soundEffects.playSoundAt("die", param)
