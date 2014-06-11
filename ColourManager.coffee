
define [], () ->
  class ColourManager
    constructor: () ->
      @defaultColours = {background:"#0b0d22",fogofwar:"#ffffff",deathzone:"#00a8d0",tangle:"#e6d256",tangleoutline:"#9f783e"}
      # #{background:"#0b0d22",fogofwar:"#004667",deathzone:"#00cca4",tangle:"#464546",tangleoutline:"#7777ff"}
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
      @outputElement.value = "{"+(name + ":" + ('"'+el.value+'"') for name, el of @formElements)+"}"
