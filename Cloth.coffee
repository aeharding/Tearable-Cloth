#
#Copyright (c) 2013 Suffick at Codepen (http://codepen.io/suffick) and GitHub (https://github.com/suffick)
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#

# settings
canvas = undefined
ctx = undefined
cloth = undefined
boundsx = undefined
boundsy = undefined
mouse =
  down: false
  button: 1
  x: 0
  y: 0
  px: 0
  py: 0
physics_accuracy = 3
mouse_influence = 20
mouse_cut = 5
gravity = 1200
cloth_height = 30
cloth_width = 50
start_y = 20
spacing = 7
tear_distance = 60
window.requestAnimFrame = window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
  window.setTimeout callback, 1000 / 60
  return


update = ->
  ctx.clearRect 0, 0, canvas.width, canvas.height
  cloth.update()
  cloth.draw()
  requestAnimFrame update
  return
start = ->
  canvas.onmousedown = (e) ->
    mouse.button = e.which
    mouse.px = mouse.x
    mouse.py = mouse.y
    rect = canvas.getBoundingClientRect()
    mouse.x = e.clientX - rect.left
    mouse.y = e.clientY - rect.top
    mouse.down = true

    e.preventDefault()
    return

  canvas.onmouseup = (e) ->
    mouse.down = false
    e.preventDefault()
    return

  canvas.onmousemove = (e) ->
    mouse.px = mouse.x
    mouse.py = mouse.y
    rect = canvas.getBoundingClientRect()
    mouse.x = e.clientX - rect.left
    mouse.y = e.clientY - rect.top
    e.preventDefault()

    return

  canvas.oncontextmenu = (e) ->
    e.preventDefault()
    return

  boundsx = canvas.width - 1
  boundsy = canvas.height - 1
  ctx.strokeStyle = "#888"
  cloth = new Cloth()
  update()
  return


Point = (x, y) ->
  @x = x
  @y = y
  @px = x
  @py = y
  @vx = 0
  @vy = 0
  @pin_x = null
  @pin_y = null
  @constraints = []
  return

Point::update = (delta) ->
  if mouse.down
    diff_x = @x - mouse.x
    diff_y = @y - mouse.y
    dist = Math.sqrt(diff_x * diff_x + diff_y * diff_y)
    if mouse.button is 1
      if dist < mouse_influence
        @px = @x - (mouse.x - mouse.px) * 1.8
        @py = @y - (mouse.y - mouse.py) * 1.8
    else @constraints = []  if dist < mouse_cut
  @add_force 0, gravity
  delta *= delta
  nx = @x + ((@x - @px) * .99) + ((@vx / 2) * delta)
  ny = @y + ((@y - @py) * .99) + ((@vy / 2) * delta)
  @px = @x
  @py = @y
  @x = nx
  @y = ny
  @vy = @vx = 0
  return

Point::draw = ->
  return  if @constraints.length <= 0
  i = @constraints.length
  @constraints[i].draw()  while i--
  return

Point::resolve_constraints = ->
  if @pin_x? and @pin_y?
    @x = @pin_x
    @y = @pin_y
    return
  i = @constraints.length
  @constraints[i].resolve()  while i--
  if @x > boundsx
    @x = 2 * boundsx - @x
  else @x = 2 - @x  if @x < 1
  if @y > boundsy
    @y = 2 * boundsy - @y
  else @y = 2 - @y  if @y < 1
  return

Point::attach = (point) ->
  @constraints.push new Constraint(this, point)
  return

Point::remove_constraint = (lnk) ->
  i = @constraints.length
  @constraints.splice i, 1  if @constraints[i] is lnk  while i--
  return

Point::add_force = (x, y) ->
  @vx += x
  @vy += y
  return

Point::pin = (pinx, piny) ->
  @pin_x = pinx
  @pin_y = piny
  return

Constraint = (p1, p2) ->
  @p1 = p1
  @p2 = p2
  @length = spacing
  return

Constraint::resolve = ->
  diff_x = @p1.x - @p2.x
  diff_y = @p1.y - @p2.y
  dist = Math.sqrt(diff_x * diff_x + diff_y * diff_y)
  diff = (@length - dist) / dist
  @p1.remove_constraint this  if dist > tear_distance
  px = diff_x * diff * 0.5
  py = diff_y * diff * 0.5
  @p1.x += px
  @p1.y += py
  @p2.x -= px
  @p2.y -= py
  return

Constraint::draw = ->
  ctx.moveTo @p1.x, @p1.y
  ctx.lineTo @p2.x, @p2.y
  return

Cloth = ->
  @points = []
  start_x = canvas.width / 2 - cloth_width * spacing / 2
  y = 0

  while y <= cloth_height
    x = 0

    while x <= cloth_width
      p = new Point(start_x + x * spacing, start_y + y * spacing)
      x isnt 0 and p.attach(@points[@points.length - 1])
      y is 0 and p.pin(p.x, p.y)
      y isnt 0 and p.attach(@points[x + (y - 1) * (cloth_width + 1)])
      @points.push p
      x++
    y++
  return

Cloth::update = ->
  i = physics_accuracy
  while i--
    p = @points.length
    @points[p].resolve_constraints()  while p--
  i = @points.length
  @points[i].update .016  while i--
  return

Cloth::draw = ->
  ctx.beginPath()
  i = cloth.points.length
  cloth.points[i].draw()  while i--
  ctx.stroke()
  return

window.onload = ->
  canvas = document.getElementById("c")
  ctx = canvas.getContext("2d")
  canvas.width = 560
  canvas.height = 350
  start()
  return
