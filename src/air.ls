
metrics = do
  NO2: {}
  'PM2.5':
    domain: [0, 20, 35, 70, 100]
    name: \細懸浮
    unit: \μg/m³
  PM10:
    domain: [0, 50, 150, 350, 420]
    unit: \μg/m³
    name: \懸浮微粒
  PSI:
    domain: [0, 50, 100, 200, 300]
    name: \污染指數
  SO2:
    name: \二氧化硫
  CO: {}
  O3:
    domain: [0, 40, 80, 120, 300]
    name: \臭氧
    unit: \ppb

<- $

window-width = $(window) .width!

if window-width > 998
  width = $(window) .height! / 4 * 3
  width <?= 687
  margin-top = \0px
else
  width = $(window) .width!
  margin-top = \65px

height = width * 4 / 3

wrapper = d3.select \body
          .append \div
          .style \width, width + \px
          .style \height, height + \px
          .style \position, \absolute
          .style \margin-top, margin-top
          .style \top, \0px
          .style \left, \0px
          .style \overflow, \hidden

canvas = wrapper.append \canvas
          .attr \width, width
          .attr \height, height
          .style \position, \absolute

canvas.origin = [0 0]
canvas.scale = 1

svg = d3.select \body
      .append \svg
      .attr \width, width
      .attr \height, height
      .style \position, \absolute
      .style \top, \0px
      .style \left, \0px
      .style \margin-top, margin-top

g = svg.append \g
      .attr \id, \taiwan
      .attr \class, \counties

history = d3.select \#history
  .style \top \-400px
  .style \left \-200px
  .style \width \400px
  .style \height \200px
  .style \z-index 100

x-off = width - 100 - 40
y-off = height - (32*7) - 40

legend = svg.append \g
  .attr \class, \legend
  .attr "transform" ->
    "translate(#{x-off},#{y-off})"

legend
  ..append \rect
    .attr \width 100
    .attr \height 32*7
    .attr \x 20
    .attr \y 0
    .style \fill \#000000
    .style \stroke \#555555
    .style \stroke-width 2
  ..append \svg:image
    .attr \xlink:href '/img/g0v-2line-black-s.png'
    .attr \x 20
    .attr \y 1
    .attr \width 100
    .attr \height 60
  ..append \text
    .attr \x 33
    .attr \y 30*7 + 10
    .text 'env.g0v.tw'
    .style \fill \#EEEEEE
    .style \font-size \13px
    .style \font-family \Orbitron

$ document .ready ->
  panel-width = $ \#main-panel .width!
  if window-width - panel-width > 1200
    $ \#main-panel .css \margin-right, panel-width

  $ \.data.button .on \click ->
    it.preventDefault!
    $ \#main-panel .toggle!
    $ \#info-panel .hide!

  $ \.forcest.button .on \click ->
    it.preventDefault!
    $ \#info-panel .toggle!
    $ \#main-panel .hide!

  $ \.launch.button .on \click ->
    it.preventDefault!
    $ \#info-panel .hide!
    sidebar = $ '.sidebar'
    sidebar.sidebar \toggle

# inspector = d3.select \body
#               .append \div
#               .attr \class \inspector
#               .style \opacity 0

# station-label = inspector.append "p"
# rainfall-label = inspector.append "p"


min-latitude = 21.5 # min-y
max-latitude = 25.5 # max-y
min-longitude = 119.5 # min-x
max-longitude = 122.5 # max-x
dy = (max-latitude - min-latitude) / height
dx = (max-longitude - min-longitude) / width

proj = ([x, y]) ->
  [(x - min-longitude) / dx, height - (y - min-latitude) / dy]

path = d3.geo.path!projection proj

### Draw Taiwan
draw-taiwan = (countiestopo) ->

  counties = topojson.feature countiestopo, countiestopo.objects['twCounty2010.geo']

  g.selectAll 'path'
    .data counties.features
    .enter!append 'path'
    .attr 'class', -> \q-9-9
    .attr 'd', path

ConvertDMSToDD = (days, minutes, seconds) ->
  days = +days
  minutes = +minutes
  seconds = +seconds
  dd = minutes/60 + seconds/(60*60)
  return if days > 0
    days + dd
  else
    days - dd

draw-stations = (stations) ->
  g.selectAll \circle
    .data stations
    .enter!append 'circle'
    .style \stroke \white
    .style \fill \none
    .attr \r 2
    .attr "transform" ->
        "translate(#{ proj [+it.lng, +it.lat] })"

var current-metric, current-unit
var color-of
var stations

set-metric = (name) ->
  $ \#history .hide!
  history.chart.unload current-metric.toLowerCase! if current-metric
  current-metric := name
  color-of := d3.scale.linear()
  .domain metrics[name].domain ? [0, 50, 100, 200, 300]
  .range [ d3.hsl(100, 1.0, 0.6)
           d3.hsl(60, 1.0, 0.6)
           d3.hsl(30, 1.0, 0.6)
           d3.hsl(0, 1.0, 0.6)
           d3.hsl(0, 1.0, 0.1) ]
  current-unit := metrics[name].unit ? ''

  add-list stations

  legend.selectAll("g.entry").data color-of.domain!
    ..enter!append \g .attr \class \entry
      ..append \rect
      ..append \text
    ..each (d, i) ->
      d3.select @
        ..select 'rect'
          .attr \width 20
          .attr \height 20
          .attr \x 30
          .attr \y -> (i+2)*30
          .style \fill (d) -> color-of d
        ..select \text
          .attr \x 55
          .attr \y -> (i+2)*30+15
          .attr \d \.35em
          .text -> &0 + current-unit
          .style \fill \#AAAAAA
          .style \font-size \10px
    ..exit!remove!

  draw-heatmap stations

draw-segment = (d, i) ->
  d3.select \#station-name
  .text d.name

  if epa-data[d.name]? and not isNaN epa-data[d.name][current-metric]
    raw-value = (parseInt epa-data[d.name][current-metric]) + ""
    update-seven-segment (" " * (0 >? 4 - raw-value.length)) + raw-value
  else
    update-seven-segment "----"

add-list = (stations) ->
  list = d3.select \div.sidebar
  list.selectAll \a
    .data stations
    .enter!append 'a'
    .attr \class, \item
    .text ->
      it.SITE
    .on \click (d, i) ->
      draw-segment d, i
      $ \.launch.button .click!
      $ \#main-panel .css \display, \block

#console.log [[+it.longitude, +it.latitude, it.name] for it in stations]
#root = new Firebase "https://cwbtw.firebaseio.com"
#current = root.child "rainfall/current"

epa-data = {}

# [[x, y, z], …]
samples = {}


# p1: [x1, y1]
# p2: [x2, y2]
# return (x1-x2)^2 + (y1-y2)
distanceSquare = ([x1, y1], [x2, y2]) ->
  (x1 - x2) ** 2 + (y1 - y2) ** 2

# samples: [[x, y, z], …]
# power: positive integer
# point: [x, y]
# return z
idw-interpolate = (samples, power, point) ->
  sum = 0.0
  sum-weight = 0.0
  for s in samples
    d = distanceSquare(s, point)
    return s[2] if d == 0.0
    weight = 1.0 / (d * d) # Performance Hack: Let power = 4 for fast exp calculation.
    sum := sum + weight
    sum-weight := sum-weight + weight * if isNaN s[2] => 0 else s[2]
  sum-weight / sum




y-pixel = 0

plot-interpolated-data = (ending) ->
  y-pixel := height

  steps = 2
  starts = [ 2 to 2 * (steps - 1) by 2 ]

  render-line = ->
    c = canvas.node!.getContext \2d
    for x-pixel from 0 to width by 2
      y = min-latitude + dy * ((y-pixel + zoom.translate![1] - height) / zoom.scale! + height) 
      x = min-longitude + dx * ((x-pixel - zoom.translate![0]) / zoom.scale!)
      z = 0 >? idw-interpolate samples, 4.0, [x, y]

      c.fillStyle = color-of z
      c.fillRect x-pixel, height - y-pixel, 2, 2

    if y-pixel >= 0
      y-pixel := y-pixel - 2 * steps
      set-timeout render-line, 0
    else if starts.length > 0
      y-pixel := height - starts.shift!
      set-timeout render-line, 0
    else if ending
      set-timeout ending, 0

  render-line!

# value should be a four-character-length string.
update-seven-segment = (value-string) ->
  pins = "abcdefg"
  seven-segment-char-map =
    ' ': 0x00
    '-': 0x40
    '0': 0x3F
    '1': 0x06
    '2': 0x5B
    '3': 0x4F
    '4': 0x66
    '5': 0x6D
    '6': 0x7D
    '7': 0x07
    '8': 0x7F
    '9': 0x6F

  d3.selectAll \.seven-segment
    .data value-string
    .each (d, i) ->
      bite = seven-segment-char-map[d]

      for i from 0 to pins.length - 1
        bit = Math.pow 2 i
        d3.select this .select ".#{pins[i]}" .classed \on, (bit .&. bite) == bit

function piped(url)
  url -= /^https?:\/\//
  return "http://www.corsproxy.com/" + url

#current.on \value ->
draw-heatmap = (stations) ->
  d3.select \#rainfall-timestamp
    .text "#{epa-data.士林.PublishTime}"

  d3.select \#station-name
    .text "已更新"

  update-seven-segment "    "

  samples := for st in stations when epa-data[st.name]?
    val = parseFloat epa-data[st.name][current-metric]
    # XXX mark NaN stations
    continue if isNaN val
    [+st.lng, +st.lat, val]

  # update station's value
  svg.selectAll \circle
    .data stations
    .style \fill (st) ->
      if epa-data[st.name]? and not isNaN epa-data[st.name][current-metric]
        color-of parseFloat epa-data[st.name][current-metric]
      else
        \#FFFFFF
    .on \mouseover (d, i) ->
      draw-segment d, i
      {clientX: x, clientY: y} = d3.event
      history
        .style \left x + \px
        .style \top y + \px

      sitecode = d.SITE_CODE
      err, req <- d3.xhr piped "http://graphite.gugod.org/render/?_salt=1392034055.328&lineMode=connected&from=-24hours&target=epa.aqx.site_code.#{sitecode}.#{current-metric.toLowerCase!.replace \. ''}&format=csv"
      datum = d3.csv.parseRows req.responseText, ([_, date, value]) ->
        { date, value: parse-float value}
      return unless datum.length
      history.chart.load columns: [
        [current-metric.toLowerCase!] ++ [value for {value} in datum]
        ['x'] ++ [date for {date} in datum]
      ]

      $ \#history .show!
      history.chart.resize!

  # plot interpolated value
  plot-interpolated-data!

setup-history = ->
  chart = c3.generate do
    bindto: '#history'
    data:
      x: 'x'
      x_format: '%Y-%m-%d %H:%M:%S'
      columns: [
        ['x', '2014-01-01 00:00:00']
        ['pm2.5', 0]
      ]
    legend: {-show}
    axis:
      x: {type : 'timeseries' }
  history.chart = chart

draw-all = (_stations) ->
  stations := for s in _stations
    s.lng = ConvertDMSToDD ...(s.SITE_EAST_LONG.split \,)
    s.lat = ConvertDMSToDD ...(s.SITE_NORTH_LAT.split \,)
    s.name = s.SITE
    s
  draw-stations stations
  <- d3.csv piped 'http://opendata.epa.gov.tw/ws/Data/AQX/?$orderby=SiteName&$skip=0&$top=1000&format=csv'
  epa-data := {[e.SiteName, e] for e in it}
  set-metric \PM2.5
  $ \.psi .click ->
    set-metric \PSI
  $ \.pm10 .click ->
    set-metric \PM10
  $ \.pm25 .click ->
    set-metric \PM2.5
  $ \.o3 .click ->
    set-metric \O3

setup-history!

zoom = d3.behavior.zoom!
  .on \zoom ->
    g.attr \transform 'translate(' + d3.event.translate.join(\,) + ')scale(' + d3.event.scale + ')'
    g.selectAll \path
      .attr \d path.projection proj
    canvas
      .style \transform-origin, 'top left'
      .style \transform, \translate( + (zoom.translate![0] - canvas.origin[0]) + 'px,' + (zoom.translate![1] - canvas.origin[1]) + 'px)' + \scale( + zoom.scale! / canvas.scale + \)
  .on \zoomend ->
    canvas := wrapper.insert \canvas, \canvas
              .attr \width, width
              .attr \height, height
              .style \position, \absolute
    canvas.origin = zoom.translate!
    canvas.scale = zoom.scale!
    plot-interpolated-data ~> wrapper.selectAll \canvas .data [0] .exit!.remove!

if localStorage.countiestopo and localStorage.stations
  <- setTimeout _, 1ms
  draw-taiwan JSON.parse localStorage.countiestopo
  stations = JSON.parse localStorage.stations
  draw-all stations
  svg.call zoom
else
  countiestopo <- d3.json "/twCounty2010.topo.json"
  try localStorage.countiestopo = JSON.stringify countiestopo
  draw-taiwan countiestopo
  stations <- d3.csv "/epa-site.csv"
  try localStorage.stations = JSON.stringify stations
  draw-all stations
do
  forecast <- d3.csv piped 'http://opendata.epa.gov.tw/ws/Data/AQF/?$orderby=AreaName&$skip=0&$top=1000&format=csv'
  first = forecast[0]
  d3.select \#forecast
    .text first.Content
  d3.select \#info-panel
    .text first.Content
