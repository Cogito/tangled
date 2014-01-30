
define [], () ->
  class ColourManager
    constructor: () ->
      @defaultColours = {
        background: "#FF9856"
        fogofwar: "#FF6400"
        deathzone: "#00CCA4"
        tangle: "#FFFFFF"
        tangleoutline: "#7777FF"
      }
      @formElements = {
        background: document.getElementById('colour-background')
        fogofwar: document.getElementById('colour-fogofwar')
        deathzone: document.getElementById('colour-deathzone')
        tangle: document.getElementById('colour-tangle')
        tangleoutline: document.getElementById('colour-tangleoutline')
      }
      @outputElement = document.getElementById('colour-output')
      @setDefaults()
      @updateOutput()

    getColour: (colour) ->
      @formElements[colour]?.value

    setDefaults: ->
      for name, el of @formElements
        el.value = @defaultColours[name]

    updateOutput: ->
      @outputElement.value = "{"+(name + ":" + el.value for name, el of @formElements)+"}"
