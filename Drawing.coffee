define ["utils", "Source"], (utils, Source) ->
  class Drawing
    constructor: (@game) ->
      @tangle = @game.tangle
      @canvas = @game.canvas
      @ctx = @canvas.getContext('2d')
      @tangleCtx = @game.tangleCanvas.getContext('2d')
      @fogOfWarCtx = @game.fogOfWarCanvas.getContext('2d')

    render: (sources, tangle) ->
      @clear(@ctx, @game.colourManager.getColour("fogofwar"))
      @fogOfWarCtx.clearRect(0,0,@canvas.width,@canvas.width)
      @drawFogOfWar(@fogOfWarCtx, tangle.allNodes())
      @clear(@tangleCtx, @game.colourManager.getColour("background"))
      @drawNodes(@tangleCtx, sources)
      @drawTangle(@tangleCtx, tangle)
      @fogOfWarCtx.globalCompositeOperation = "source-in"
      @fogOfWarCtx.drawImage(@game.tangleCanvas, 0, 0)
      @fogOfWarCtx.globalCompositeOperation = "source-over"
      @ctx.drawImage(@game.fogOfWarCanvas, 0, 0)

    clear: (context, bgColour = "rgb(0,0,0)") ->
      context.save()
      canvas = context.canvas
      #context.fillStyle = @game.colourManager.getColour("deathzone")
      context.fillStyle = bgColour
      context.fillRect(0, 0, canvas.width, canvas.height)
      #context.fillRect(@game.border, @game.border, @frameWidth - 2 * @game.border, @frameHeight - 2 * @game.border)
      context.restore()

    drawFogOfWar: (context, nodes) ->
      context.fillStyle = "#000000" #rgb(255,255,255)"
      context.beginPath()
      #console.log nodes.length
      for node in nodes #when not node instanceof Source
        @drawNodeMask(context, node)
      context.fill()


    drawTangle: (context, tangle) ->
      context.strokeStyle = @game.colourManager.getColour("tangleoutline")
      context.fillStyle = @game.colourManager.getColour("tangle")
      context.beginPath()
      for node in tangle.allNodes() when not node?.isDying
        @drawNode(context, node)
      context.fill()
      context.stroke()
      for node in tangle.allNodes() when node?.isDying
        context.fillStyle = "rgba(255,255,255,"+node.weight / tangle.maxNodeWeight+")"
        context.strokeStyle = "rgba(255,0,0,1)"
        context.beginPath()
        @drawNode(context, node)
        context.fill()
        context.stroke()

    drawConnection: (context, node1, node2) ->
      if (!node1 or !node2 or node1 is node2 or node2.weight < node1.weight)
        return
      deviationAngle = 0.5
      deviationRadius = 1
      leftLine = utils.leftOuterLineBetween(node1, node2)
      leftCP1 = utils.offsetFrom(node1, node1.size() + deviationRadius, leftLine.startAngle - deviationAngle)
      leftCP2 = utils.offsetFrom(node2, node2.size() + deviationRadius, leftLine.endAngle + deviationAngle)
      rightLine = utils.leftOuterLineBetween(node2, node1)
      rightCP1 = utils.offsetFrom(node2, node2.size() + deviationRadius, rightLine.startAngle - deviationAngle)
      rightCP2 = utils.offsetFrom(node1, node1.size() + deviationRadius, rightLine.endAngle + deviationAngle)

      @moveTo(context, leftLine.start)
      @bezierCurveTo(context, leftCP1, leftCP2, leftLine.end)
      @lineTo(context, rightLine.start)
      @bezierCurveTo(context, rightCP1, rightCP2, rightLine.end)
      @lineTo(context, leftLine.start)

    drawNode: (context, node) ->
      radius = node.size()
      if node.numConnections() < 1
        #@ctx.fillStyle = if node.active then "rgba(255,0,255,0.5)" else "rgba(255,255,255,0.5)"
        @moveTo(context, node)
        @arc(context, node, radius, 0 , 2 * Math.PI)
      else
        #@ctx.fillStyle = node.colour()
        sortedConns = node.sortedConns()
        startp = utils.offsetFrom(node, node.size(), utils.middleAngle(sortedConns, sortedConns.length - 1, true))
        @moveTo(context, startp)
        for c, i in sortedConns
          p = utils.offsetFrom(node, node.size(), utils.middleAngle(sortedConns, i, true))
          @lineTo(context, p)
        @lineTo(context, startp)
      for conn in node.sortedConns()
        @drawConnection(context, node, conn?.node)

    drawNodes: (context, nodes) ->
      context.strokeStyle = "rgba(255,255,255,0.15)"
      context.fillStyle = "rgba(255,255,255,1)"
      context.beginPath()
      @drawNode(context, node) for node in nodes
      context.fill()
      context.stroke()

    drawNodeMask: (context, node) ->
      if node instanceof Source
        radius = node.weight * 5
      else
        radius = node.tangle.maxGrowDistance * node.weight
      @moveTo(context, node)
      @arc(context, node, radius, 0 , 2 * Math.PI)
      return

    moveTo: (context, p) ->
      newp = @game.viewport.sceneToCanvas(p)
      context.moveTo(newp.x, newp.y)

    lineTo: (context, p) ->
      newp = @game.viewport.sceneToCanvas(p)
      context.lineTo(newp.x, newp.y)

    arc: (context, p, radius, startAngle, endAngle) ->
      newp = @game.viewport.sceneToCanvas(p)
      newRadius = radius * @game.viewport.canvas.width / @game.viewport.view.width()
      context.arc(newp.x, newp.y, newRadius, startAngle, endAngle)

    bezierCurveTo: (context, cp1, cp2, end) ->
      newCP1 = @game.viewport.sceneToCanvas(cp1)
      newCP2 = @game.viewport.sceneToCanvas(cp2)
      newEnd = @game.viewport.sceneToCanvas(end)
      context.bezierCurveTo(newCP1.x, newCP1.y, newCP2.x, newCP2.y, newEnd.x, newEnd.y)
