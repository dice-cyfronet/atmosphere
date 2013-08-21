#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap
#= require_tree .

#turbolinks spinner
$(document).on 'page:fetch', ->
  $('.turbolink-spinner').removeClass('hide')
  $('.turbolink-spinner').fadeIn()

$(document).on 'page:receive', ->
  $('.turbolink-spinner').fadeOut()

#turbolinks and tooltips
$(document).on "ready page:change", ->
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')

$ ->
  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 3000

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')