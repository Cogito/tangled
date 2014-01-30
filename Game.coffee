define ["utils", "Tangle", "Source", "Drawing", "SoundEffects", "ColourManager"], (utils, Tangle, Source, Drawing, SoundEffects, ColourManager) ->
  class Game
    constructor: (@canvas) ->
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

      @soundEffects = new SoundEffects(@canvas)

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
      document.getElementById('fps').innerHTML = @tangle.allNodes().length + " nodes; " + Math.round(@fps) + " fps";
      if not @paused then window.requestAnimationFrame(@mainLoop)
      if !@startTime
        @startTime = time
        console.log @startTime
      @time = time - @startTime

      if @time >= @nextTick
        @update()
        @nextTick += 100
      @draw()
      @colourManager.updateOutput()

    draw: ->
      @drawing.render(@sources, @tangle)

    update: ->
      @tangle.growRandomly(1, 0.1)
      @tangle.growRandomly(2, 0.0001)

      hit = @lastKnownMouse
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

      @tangle.killDyingNodes()
      @tangle.prepareTransfers()
      @tangle.doTransfers()

    setupEventHandlers: ->
      @canvas.addEventListener "mousemove", (event) =>
        @lastKnownMouse = utils.getMouse(event, @canvas)
      # Super simple dragging detection. TODO will need to revisit when behaviour advances
      @canvas.addEventListener "mousedown", (event) =>
        @mouseDragging = true
      @canvas.addEventListener "mouseup", (event) =>
        @mouseDragging = false
        @tangle.activeNode = null

    inBounds: (p) ->
      p.x > @border and p.x < @width - @border and p.y > @border and p.y < @height - @border

    playSound: (event, param) ->
      switch event
        when "grow_active", "grow_random"
          @soundEffects.playSoundAt("grow", param)
        when "die"
          @soundEffects.playSoundAt("die", param)
