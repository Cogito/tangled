
define [], () ->
  class ColourManager
    constructor: () ->
      storedColours = localStorage.getItem("defaultColours")
      if storedColours
        @defaultColours = JSON.parse(storedColours)
      else
        @defaultColours = {background:"#0b0d22",fogofwar:"#ffffff",deathzone:"#00a8d0",tangle:"#e6d256",tangleoutline:"#9f783e"}
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
      colours = {}
      colours[name] = el.value for name, el of @formElements
      localStorage.setItem("defaultColours", JSON.stringify(colours))
      @outputElement.value = JSON.stringify(colours)
