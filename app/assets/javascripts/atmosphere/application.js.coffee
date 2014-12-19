#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require jquery.turbolinks
#= require nprogress
#= require nprogress-turbolinks
#= require bootstrap
#= require highcharts
#= require ./billing

$ ->
  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 5000

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')