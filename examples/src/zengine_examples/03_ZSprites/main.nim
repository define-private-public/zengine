# Example useage of ZSprites

import zengine, sdl2, opengl


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 03_ZSprites")
zengine.gui.init()


let sprite = initZSprite("../../../../specs/zsprite_examples/BlauGeist.zsprite")


# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: Vector3(x: 4, y: 2, z: 4),
    target: Vector3(x: 0, y: 1.8, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
    fovY: 60
  )


# Use a first person camera
# TODO need an ortho camera
camera.setMode(CameraMode.FirstPerson)


# Main Game loop
while running:
  # Reset

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

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  drawText("Zengine ZSprites!", 8, 8, 16, ZColor(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF))

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()
