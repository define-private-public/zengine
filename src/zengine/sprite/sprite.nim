# sprite/sprite.nim
#
# Sprite is a base object for Sprite types in Zengine, such as ZSprite.  It is a
# child object of Entity3D
from ../entity3d import Entity3D
from glm import Vec3f

# The actual sprite object
type Sprite* = ref object of Entity3D
  visability*: float    # [0.0, 1.0], visability of the frame
  scale*: Vec3f         # Scale
  # TODO non-center orientation origin


# ============== #
# Sprite Methods #
# ============== #

# Update the sprite's logic. `dt` is the change in time (in seconds) since the
# last logical update.  E.g. if we're logically updating at 100 FPS, then `0.01`
# is what should be passed into this.  (NOTE: You're game probably isn't going
# to be at 100 logical FPS.  It's probably going to flucuate all the time.  This
# is meant to be an "as if," examle).
method update*(self: Sprite; dt: float) {.base.}=
  raise newException(Exception, "Sprite.update() should not be directly called.")


# Draw the sprite.  Will call the underlying OpenGL methods to draw the sprite
# to the screen
method draw*(self: Sprite) {.base.}=
  raise newException(Exception, "Sprite.draw() should not be directly called.")




