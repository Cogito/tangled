define ["utils", "Tangle", "Source", "Drawing"], (utils, Tangle, Source, Drawing) ->
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

      @setupEventHandlers()

      @tangle = new Tangle(this)

      for i in [1..10]
        @tangle.addChain [new Source(
          this,
          2 * @border + (@width - 4 * @border) * Math.random(),
          2 * @border + (@height - 4 * @border) * Math.random(),
          10
        )]

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
      document.getElementById('fps').innerHTML = "(" + @fps_now + "-" + @fps_last + ") " + Math.round(@fps) + " fps";
      if not @paused then window.requestAnimationFrame(@mainLoop)
      if !@startTime
        @startTime = time
        console.log @startTime
      @time = time - @startTime

      if @time >= @nextTick
        @update()
        @nextTick += 100
      @draw()

    draw: ->
      @drawing.clear()
      @drawing.drawTangle(@tangle)

    update: ->
      @tangle.growRandomly(1, 0.1)
      @tangle.growRandomly(2, 0.0001)

      hit = @lastKnownMouse
      if hit and @mouseDragging and @tangle.nodes.length > 0
        if not @tangle.activeNode
          closest = utils.findClosestInSet(hit, @tangle.findNodesNear(hit))
          if closest
            distToClosest = utils.distanceBetween(hit, closest) - closest.weight
            if distToClosest < @tangle.maxGrowDistance
              @tangle.activeNode = closest
        else
          distToActive = utils.distanceBetween(hit, @tangle.activeNode) - @tangle.activeNode.weight
          if @mouseDragging and distToActive >= @tangle.minGrowDistance
            distance = @tangle.activeNode.weight + @tangle.minGrowDistance + Math.random() * (@tangle.maxGrowDistance - @tangle.minGrowDistance)
            p = utils.offsetFrom(@tangle.activeNode, distance, Math.atan2(hit.y - @tangle.activeNode.y, hit.x - @tangle.activeNode.x))
            newNode = @tangle.grow(p)
            @tangle.activeNode = newNode

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