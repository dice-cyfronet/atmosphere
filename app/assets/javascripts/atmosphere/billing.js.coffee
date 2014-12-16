class @Billing
  constructor: (modeName, monthLabels, dataSeries) ->

    $('#billing-chart').highcharts
      chart:
        type: 'column'
      title:
        text: 'Funds consumption by month for ' + modeName
      xAxis:
        title:
          text: 'Last 12 months'
        categories: monthLabels
      yAxis:
        title:
          text: 'Consumption distributed by currency'
      tooltip:
        formatter: ->
          '<b>' + this.x + '</b><br/>' +
          this.series.name + ': ' + (this.y / 10000) + '<br/>' +
          'Total: ' + this.point.stackTotal
      plotOptions:
        column:
          stacking: 'normal'
          dataLabels:
            enabled: true
            color:
              (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white'
            style:
              textShadow: '0 0 3px black, 0 0 3px black'
            formatter: ->
              if this.y != 0
                this.y / 10000
              else
                null
      series: dataSeries
