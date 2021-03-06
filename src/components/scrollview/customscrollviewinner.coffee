KDCustomHTMLView = require './../../core/customhtmlview'
KDScrollView     = require './scrollview'
KDScrollThumb    = require './scrollthumb'
KDScrollTrack    = require './scrolltrack'

module.exports = class KDCustomScrollViewWrapper extends KDScrollView

  SPACEBAR  = 32
  PAGEUP    = 33
  PAGEDOWN  = 34
  END       = 35
  HOME      = 36

  constructor: (options = {}, data) ->

    options.bind = KD.utils.curry 'keydown', options.bind
    options.attributes ?= {}
    options.attributes.tabindex ?= "0"

    @globalKeydownEventBound = no

    super options, data

    @on 'MutationHappened', @bound "toggleGlobalKeydownEventOnSizeCheck"


  scroll: (event) ->

    if @verticalThumb.beingDragged or @horizontalThumb.beingDragged

      return KD.utils.stopDOMEvent event


  mouseWheel: (event) ->

    super

    {deltaX, deltaY, deltaFactor} = event

    speed = deltaFactor or @getOptions().mouseWheelSpeed or 1
    x     = -deltaX
    y     = -deltaY

    resX  = if x isnt 0 and @getScrollWidth() > @horizontalThumb.getTrackSize()
    then  @_scrollHorizontally {speed, velocity : x}
    else  no
    resY  = if y isnt 0 and @getScrollHeight() > @verticalThumb.getTrackSize()
    then  @_scrollVertically {speed, velocity : y}
    else  no

    stop  = if Math.abs(x) > Math.abs(y) then resX else resY

    KD.utils.stopDOMEvent event  unless stop

    return !stop


  _scrollVertically: do ->

    lastPosition = 0

    ({speed, velocity})->

      stepInPixels = velocity * speed
      actPosition  = @getScrollTop()
      newPosition  = actPosition + stepInPixels
      shouldStop   = if velocity > 0
      then lastPosition > newPosition
      else lastPosition < newPosition

      @setScrollTop lastPosition = newPosition

      return shouldStop


  _scrollHorizontally: do ->

    lastPosition = 0

    ({speed, velocity})->

      stepInPixels = velocity * speed
      actPosition  = @getScrollLeft()
      newPosition  = actPosition - stepInPixels
      shouldStop   = if velocity > 0
      then lastPosition < newPosition
      else lastPosition > newPosition

      @setScrollLeft lastPosition = newPosition

      return shouldStop


  toggleGlobalKeydownEventOnSizeCheck: ->

    winHeight = $(window).height()
    needToBind = @getHeight() >= winHeight
    @toggleGlobalKeydownEvent needToBind


  toggleGlobalKeydownEvent: (needToBind) ->

    eventName = "keydown.customscroll#{@getId()}"

    if needToBind
      $(document).on eventName, @bound "keyDown"  unless @globalKeydownEventBound
    else
      $(document).off eventName  if @globalKeydownEventBound

    @globalKeydownEventBound = needToBind


  destroy: ->

    @toggleGlobalKeydownEvent no
    super


  pageUp: ->
    @scrollTo top : Math.max @getScrollTop() - @getHeight(), 0


  pageDown: ->
    @scrollTo top : @getScrollTop() + @getHeight()


  keyDown: (event) ->

    editables = "input,textarea,select,datalist,keygen,[contenteditable='true']"

    return yes  if ($ document.activeElement).is editables
    return yes  if not(@getDomElement().is ":visible")
    return yes  if @getScrollHeight() <= @verticalThumb.getTrackSize()

    shouldPropagate = no
    if event.which is SPACEBAR and event.shiftKey
      @pageUp()
    else
      switch event.which
        when PAGEUP then @pageUp()
        when SPACEBAR, PAGEDOWN then @pageDown()
        when END then @scrollToBottom()
        when HOME then @scrollTo top : 0
        else shouldPropagate = yes

    return shouldPropagate