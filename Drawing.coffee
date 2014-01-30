define ["utils", "Source"], (utils, Source) ->
  class Drawing
    constructor: (@game) ->
      @tangle = @game.tangle
      @canvas = @game.canvas
      @ctx = @canvas.getContext('2d')
      @tangleCtx = @game.tangleCanvas.getContext('2d')
      @fogOfWarCtx = @game.fogOfWarCanvas.getContext('2d')
      @frameWidth = @canvas.width
      @frameHeight = @canvas.height

    render: (sources, tangle) ->
      @clear(@ctx, "#FF6400")
      @drawFogOfWar(@fogOfWarCtx, tangle.allNodes())
      @clear(@tangleCtx, "#FF9856")#"rgb(50,50,70)")
      @drawNodes(@tangleCtx, sources)
      @drawTangle(@tangleCtx, tangle)
      #@ctx.drawImage(@game.tangleCanvas, 0, 0)
      @fogOfWarCtx.globalCompositeOperation = "source-in"
      @fogOfWarCtx.drawImage(@game.tangleCanvas, 0, 0)
      @fogOfWarCtx.globalCompositeOperation = "source-over"
      @ctx.drawImage(@game.fogOfWarCanvas, 0, 0)

    clear: (context, bgColour = "rgb(0,0,0)") ->
      context.save()
      context.fillStyle = @tangle.deadzoneFillStyle
      context.fillRect(0, 0, @frameWidth, @frameHeight)
      context.fillStyle = bgColour
      context.fillRect(@game.border, @game.border, @frameWidth - 2 * @game.border, @frameHeight - 2 * @game.border)
      context.restore()

    drawFogOfWar: (context, nodes) ->
      context.fillStyle = "#000000" #rgb(255,255,255)"
      context.beginPath()
      #console.log nodes.length
      for node in nodes #when not node instanceof Source
        @drawNodeMask(context, node)
      context.fill()


    drawTangle: (context, tangle) ->
      context.strokeStyle = "rgba(100,100,255,0.15)"
      context.fillStyle = tangle.innerFillStyle
      context.beginPath()
      for node in tangle.allNodes() when not node?.isDying
        @drawNode(context, node)
      context.fill()
      context.stroke()
      for node in tangle.allNodes() when node?.isDying
        context.fillStyle = "rgba(255,255,255,"+node.weight / tangle.maxNodeWeight+")"
        context.beginPath()
        @drawNode(context, node)
        context.fill()
        context.stroke()

    drawConnection: (context, node1, node2) ->
      if (!node1 or !node2 or node1 is node2 or node2.weight > node1.weight)
        return
      deviationAngle = 0.5
      deviationRadius = 1
      leftLine = utils.leftOuterLineBetween(node1, node2)
      leftCP1 = utils.offsetFrom(node1, node1.size() + deviationRadius, leftLine.startAngle - deviationAngle)
      leftCP2 = utils.offsetFrom(node2, node2.size() + deviationRadius, leftLine.endAngle + deviationAngle)
      rightLine = utils.leftOuterLineBetween(node2, node1)
      rightCP1 = utils.offsetFrom(node2, node2.size() + deviationRadius, rightLine.startAngle - deviationAngle)
      rightCP2 = utils.offsetFrom(node1, node1.size() + deviationRadius, rightLine.endAngle + deviationAngle)

      #@ctx.fillStyle = node2.colour()
      #@ctx.beginPath()
      # line between nodes
      #@ctx.moveTo(node1.x, node1.y);
      #@ctx.lineTo(node2.x, node2.y);
      #@ctx.stroke()
      # body of tangle segment
      context.moveTo(leftLine.start.x, leftLine.start.y)
      context.bezierCurveTo(leftCP1.x, leftCP1.y, leftCP2.x, leftCP2.y, leftLine.end.x, leftLine.end.y)
      context.lineTo(rightLine.start.x, rightLine.start.y)
      context.bezierCurveTo(rightCP1.x, rightCP1.y, rightCP2.x, rightCP2.y, rightLine.end.x, rightLine.end.y)
      context.lineTo(leftLine.start.x, leftLine.start.y)
      #@ctx.stroke()
      #@ctx.fill()
      #@ctx.closePath()

    drawNode: (context, node) ->
      radius = node.size()
      if node.numConnections() < 1
        #@ctx.fillStyle = if node.active then "rgba(255,0,255,0.5)" else "rgba(255,255,255,0.5)"
        context.moveTo(node.x,node.y)
        context.arc(node.x, node.y, radius, 0 , 2 * Math.PI)
      else
        #@ctx.fillStyle = node.colour()
        sortedConns = node.sortedConns()
        startp = utils.offsetFrom(node, node.size(), utils.middleAngle(sortedConns, sortedConns.length - 1, true))
        context.moveTo(startp.x, startp.y)
        for c, i in sortedConns
          p = utils.offsetFrom(node, node.size(), utils.middleAngle(sortedConns, i, true))
          context.lineTo(p.x, p.y)
        context.lineTo(startp.x, startp.y)
      @drawConnection(context, node, conn?.node) for id, conn of node.connections

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
      context.moveTo(node.x,node.y)
      context.arc(node.x, node.y, radius, 0 , 2 * Math.PI)
