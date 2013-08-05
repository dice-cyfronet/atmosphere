#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap
#= require_tree .

$ ->
  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 3000