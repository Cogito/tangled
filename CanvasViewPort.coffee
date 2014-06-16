define ["Rectangle"], (Rectangle) ->
  # The ViewPort defines a scene, the entire viewable space; and a view, a subset of that.
  # The view is mapped to a canvas, by scaling it to size
  class CanvasViewPort
    constructor: (@canvas, view) ->
      @view = view ? new Rectangle(0, 0, @canvas.width, @canvas.height)

    sceneToView: (p) ->
      {
        x: p.x - @view.x1
        y: p.y - @view.y1
      }

    viewToScene: (p) ->
      {
        x: p.x + @view.x1
        y: p.y + @view.y1
      }

    viewToCanvas: (p) ->
      {
        x: p.x * @canvas.width / @view.width()
        y: p.y * @canvas.height / @view.height()
      }

    canvasToView: (p) ->
      {
        x: p.x * @view.width() / @canvas.width
        y: p.y * @view.height() / @canvas.height
      }

    sceneToCanvas: (p) -> @viewToCanvas(@sceneToView(p))

    canvasToScene: (p) -> @viewToScene(@canvasToView(p))
