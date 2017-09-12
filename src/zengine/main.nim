# Example useage of ZSprites
import ../zengine
import sdl2, opengl, glm
import sprite
import spritebatch
import strfmt


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 03_ZSprites")
zengine.gui.init()


var
  zs = loadZSprite("../../specs/zsprite_examples/BlauGeist.zsprite")
  sb = initSpriteBatch()
#  lastFrameTime: float


# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: vec3f(4, 2, 4),
    target: vec3f(0, 1.8, 0),
    up: vec3f(0, 1, 0),
    fovY: 60
  )


# Use a first person camera
# TODO need an ortho camera
camera.setMode(CameraMode.FirstPerson)

# Play the main loop
zs.play("spin")


# Main Game loop
var clock = Timer()   # Make a timer object
clock.start()
while running:
  # Check for new input
  pollInput()

  # Poll for events
  while sdl2.pollEvent(evt):
    case evt.kind:
      # Shutdown if X button clicked
      of QuitEvent:
        running = false

      of KeyUp:
        let keyEvent = cast[KeyboardEventPtr](addr evt)
        # Shutdown if ESC pressed
        if keyEvent.keysym.sym == K_ESCAPE:
          running = false

      else:
        discard

  # Update the camera's position
  camera.update(0, 0, 0)
  zs.update(clock.deltaTime())
  echo(clock.totalTicks())
  echo(clock.deltaTime())
  echo(clock.timeElapsed())
#  echo("dt={0}, t={1}".fmt(deltaTime.format(".3f"), nowTime.format(".3f")))

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  drawText("Zengine ZSprites!", 8, 8, 24, ZColor(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF))

  sb.clear()
  sb.add(zs)
  sb.drawAll()

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

  # Step the time forward
  clock.tick()

# Shutdown
zengine.core.shutdown()
